# Kubernetes Learning Path

This directory contains my hands-on learning journey with Kubernetes, following the DevOps Directive course structure. Each resource type is deployed to my homelab k3s cluster using Ansible.

## Cluster Info
- **Type**: k3s HA cluster
- **Nodes**: 3 (k3s-server, lincoln, raven)
- **Version**: v1.34.6+k3s1
- **Storage**: Longhorn
- **GitOps**: ArgoCD

## Learning Path (Follow in Order!)

1. **[01-namespace](./01-namespace/)** - Isolate and organize resources
2. **[02-pod](./02-pod/)** - Basic building block
3. **[03-replicaset](./03-replicaset/)** - Ensure pod replicas
4. **[04-deployment](./04-deployment/)** - Manage stateless apps
5. **[05-service](./05-service/)** - Networking and load balancing
6. **[06-job](./06-job/)** - Run to completion tasks
7. **[07-cronjob](./07-cronjob/)** - Scheduled jobs
8. **[08-daemonset](./08-daemonset/)** - One pod per node
9. **[09-statefulset](./09-statefulset/)** - Stateful applications
10. **[10-configmap](./10-configmap/)** - Configuration data
11. **[11-secret](./11-secret/)** - Sensitive data
12. **[12-ingress](./12-ingress/)** - HTTP routing
13. **[13-persistentvolume](./13-persistentvolume/)** - Storage management
14. **[14-rbac](./14-rbac/)** - Access control

## Workflow for Each Section

Each section creates its own namespace to avoid conflicts and make cleanup easy:

1. **Create namespace** - Isolate this resource type's examples
2. **Study the concept** - Understand what it does
3. **Write manifests** - Create YAML files
4. **Deploy with Ansible** - Apply to cluster
5. **Test and observe** - Verify behavior
6. **Document learnings** - Update section README
7. **Clean up** - Delete namespace when done

## Commands Reference

```bash
# Deploy a specific resource type
ansible-playbook kubernetes/01-namespace/deploy.yml

# Check resources in a namespace
kubectl get all -n <namespace>

# Clean up (deletes namespace and all resources in it)
kubectl delete namespace <namespace>
```

## Source Material

Based on [DevOps Directive Kubernetes Course](https://github.com/sidpalas/devops-directive-kubernetes-course) - Section 04: Built-in Resource Types
