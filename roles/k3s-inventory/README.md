# K3S Inventory Role

Comprehensive K3S cluster monitoring and reporting role that gathers cluster health, resource usage, and log sizes across all nodes.

## Purpose

This role collects detailed information about your K3S cluster and generates JSON reports including:

- **Cluster Information**: Nodes, namespaces, pods, services, ingresses, deployments
- **Resource Metrics**: CPU, memory, disk usage per node
- **Storage**: PVC usage, Longhorn volumes
- **GitOps**: ArgoCD application sync status
- **Log Analysis**: Pod logs, container logs, system logs, journal logs
- **Alerts**: Large logs, failed pods, out-of-sync apps, unhealthy deployments

## Requirements

- **Ansible Collections**: 
  - `kubernetes.core` - Install with: `ansible-galaxy collection install kubernetes.core`
  
- **Host Requirements**:
  - `kubectl` installed on k3s_server nodes
  - Valid kubeconfig (defaults to `~/.kube/config`)
  - SSH access to all k3s_nodes with sudo privileges

- **Inventory Groups**:
  - `k3s_server` - K3S control plane node(s)
  - `k3s_nodes` - All K3S nodes (including control plane)

## Variables

See `defaults/main.yml` for all configurable variables:

```yaml
# Output configuration
report_output_dir: "/tmp/k3s-reports"
report_timestamp: "{{ ansible_facts.date_time.iso8601_basic_short }}"

# Log size thresholds (in MB)
log_size_warning_threshold: 500
log_size_critical_threshold: 1000

# Number of largest log consumers to report
top_log_consumers: 10

# Report retention (days)
report_retention_days: 30
```

## Usage

### Run inventory check on all K3S nodes

```bash
just run k3s-inventory
```

### Run with custom inventory

```bash
ansible-playbook -i inventory/production.yml site.yml --tags k3s-inventory
```


### Dry run

```bash
just dry-run k3s-inventory
```

### Integration with Kestra

Use this role in Kestra workflows for scheduled cluster reporting:

```yaml
id: k3s-cluster-report
namespace: ops

triggers:
  - id: daily
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "0 8 * * *"

tasks:
  - id: working_dir
    type: io.kestra.plugin.core.flow.WorkingDirectory
    tasks:
      - id: clone-repo
        type: io.kestra.plugin.git.Clone
        url: https://github.com/thein3rovert/nixos-config
        branch: main

      - id: run-inventory
        type: io.kestra.plugin.scripts.shell.Commands
        taskRunner:
          type: io.kestra.plugin.scripts.runner.docker.Docker
          image: willhallonline/ansible:latest
        env:
          ANSIBLE_VAULT_PASSWORD: "{{ kv('ANSIBLE_VAULT_PASSWORD') }}"
          SSH_PRIVATE_KEY: "{{ kv('SSH_PRIVATE_KEY') }}"
        beforeCommands:
          - apk add --no-cache curl bash openssh-client
          - curl -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
          - mkdir -p ~/.ssh
          - echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
          - chmod 600 ~/.ssh/id_rsa
        commands:
          - cd {{workingDir}}/ansible
          - just run k3s-inventory
```

## Output

Reports are saved to `{{ report_output_dir }}/k3s-report-<timestamp>.json`

### Report Structure

```json
{
  "timestamp": "20260627T120000",
  "cluster_info": {
    "total_nodes": 3,
    "total_namespaces": 7,
    "total_pods": 45,
    "nodes": ["k3s-server", "lincoln", "raven"]
  },
  "nodes": {
    "k3s-server": {
      "hostname": "k3s-server",
      "os": "Ubuntu 24.04.4 LTS",
      "metrics": {
        "cpu_percent": "5%",
        "memory_percent": "36%"
      },
      "log_info": {
        "total_var_log_mb": 1402,
        "pod_logs_total_mb": 850,
        "top_pod_logs": [...]
      }
    }
  },
  "summary": {
    "total_nodes": 3,
    "healthy_nodes": 3,
    "total_log_size_mb": 4200,
    "total_pod_logs_mb": 2500
  },
  "alerts": {
    "critical_count": 2,
    "warning_count": 5,
    "argocd_out_of_sync": [...]
  }
}
```

## Monitoring Recommendations

1. **Daily Reports**: Run inventory daily to track trends
2. **Alert Thresholds**: Adjust `log_size_warning_threshold` based on your cluster
3. **Log Rotation**: Use reports to identify pods that need log rotation
4. **Cleanup**: Check for old failed/evicted pods regularly
5. **ArgoCD Sync**: Monitor out-of-sync applications

## Troubleshooting

### "kubernetes.core collection not found"

```bash
ansible-galaxy collection install kubernetes.core
```

### "kubectl: command not found"

Ensure kubectl is installed on k3s_server nodes and in PATH.

### Permission denied errors

Ensure SSH keys are properly configured and user has sudo access.

### Empty metrics

Ensure metrics-server is running in the cluster:

```bash
kubectl get pods -n kube-system | grep metrics-server
```

## Tags

- `k3s-inventory` - Run full inventory
- `monitoring` - Monitoring-related tasks
- `reports` - Report generation tasks
