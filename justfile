# Ansible Playbook Runner
#
# Authentication: supply the Vault password with --ask-vault-pass or set
#                 ANSIBLE_VAULT_PASSWORD_FILE to a credential source outside
#                 this repository. Become password is stored in vars/vault.yml.
#
# Note: Host environment defaults to "production" unless specified
#       Use 'dev' as second parameter for dev hosts
#       Example: just run-host ping nixos-runner dev

# Show all commands
default:
    @just --list

# ==============================
#       PLAYBOOK EXECUTION
# ==============================

# Run all playbooks on production
[group('playbooks')]
all:
    ansible-playbook -i inventory/production.yml site.yml

# Run all playbooks on dev
[group('playbooks')]
all-dev:
    ansible-playbook -i inventory/dev.yml site.yml

# Run on specific host (default: production, specify 'dev' for dev hosts)
[group('playbooks')]
host hostname env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --limit {{ hostname }}

# ==============================
#       ROLES
# ==============================

# Run a specific role on production
[group('roles')]
run role:
    ansible-playbook -i inventory/production.yml site.yml --tags {{ role }}

# Run a specific role on dev
[group('roles')]
run-dev role:
    ansible-playbook -i inventory/dev.yml site.yml --tags {{ role }}

# Run a specific role on a specific host (default: production, add 'dev' for dev hosts)
[group('roles')]
run-host role host env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --tags {{ role }} --limit {{ host }}

# ==============================
#       GITHUB RUNNER
# ==============================

# Run a single playbook against a host
[group('playbooks')]
playbook playbook host env="production":
    GITHUB_RUNNER_TOKEN=$${GITHUB_RUNNER_TOKEN} ansible-playbook -i inventory/{{ env }}.yml "playbooks/{{ playbook }}.yml" --limit {{ host }}

# ==============================
#       DRY RUN
# ==============================

# Dry run all playbooks on production
[group('dry-run')]
dry-all:
    ansible-playbook -i inventory/production.yml site.yml --check

# Dry run all playbooks on dev
[group('dry-run')]
dry-all-dev:
    ansible-playbook -i inventory/dev.yml site.yml --check

# Dry run on specific host (default: production, add 'dev' for dev hosts)
[group('dry-run')]
dry-host hostname env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --limit {{ hostname }} --check

# Dry run a specific role on production
[group('dry-run')]
dry-run role:
    ansible-playbook -i inventory/production.yml site.yml --tags {{ role }} --check

# Dry run a specific role on dev
[group('dry-run')]
dry-run-dev role:
    ansible-playbook -i inventory/dev.yml site.yml --tags {{ role }} --check

# Dry run a specific role on a specific host (default: production, add 'dev' for dev hosts)
[group('dry-run')]
dry-run-host role host env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --tags {{ role }} --limit {{ host }} --check

# ==============================
#       INVENTORY
# ==============================

# List available roles
[group('inventory')]
list:
    @ls -1 roles/ | grep -v README.md

# List hosts in inventory
[group('inventory')]
list-hosts env="production":
    ansible-inventory -i inventory/{{ env }}.yml --list

# ==============================
#       VALIDATION
# ==============================

# Syntax check
[group('validation')]
syntax env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --syntax-check

# ==============================
#       VAULT (Ansible Vault - Encryption)
# ==============================

# Edit encrypted vault.yml
[group('vault')]
edit:
    ansible-vault edit vars/vault.yml

# Edit encrypted vault-secrets.yml (unseal keys)
[group('vault')]
edit-secrets:
    ansible-vault edit vars/vault-secrets.yml

# Encrypt vault-secrets.yml (run after pasting keys)
[group('vault')]
encrypt-secrets:
    ansible-vault encrypt vars/vault-secrets.yml

# Decrypt vault-secrets.yml (for editing manually)
[group('vault')]
decrypt-secrets:
    ansible-vault decrypt vars/vault-secrets.yml

# Change password and re-encrypt vault.yml
[group('vault')]
rekey:
    ansible-vault rekey vars/vault.yml

# Change password and re-encrypt vault-secrets.yml
[group('vault')]
rekey-secrets:
    ansible-vault rekey vars/vault-secrets.yml

# ==============================
#       HASHICORP VAULT
# ==============================

# Check Vault status
[group('hashicorp-vault')]
vault-status:
    ansible-playbook -i inventory/production.yml vault-manage.yml -e "vault_action=status"

# Restart Vault service
[group('hashicorp-vault')]
vault-restart:
    ansible-playbook -i inventory/production.yml vault-manage.yml -e "vault_action=restart"

# Unseal Vault (requires encrypted vault-secrets.yml)
[group('hashicorp-vault')]
vault-unseal:
    ansible-playbook -i inventory/production.yml vault-manage.yml -e "vault_action=unseal" -e "@vars/vault-secrets.yml"

# Restart and unseal Vault in one operation
[group('hashicorp-vault')]
vault-restart-unseal:
    ansible-playbook -i inventory/production.yml vault-manage.yml -e "vault_action=restart_unseal" -e "@vars/vault-secrets.yml"

# Clean up disk space on Vault server
[group('hashicorp-vault')]
vault-disk-cleanup:
    ansible-playbook -i inventory/production.yml vault-manage.yml -e "vault_action=disk_cleanup"

# Full recovery: cleanup, restart, and unseal
[group('hashicorp-vault')]
vault-recover:
    @echo "🔧 Step 1: Cleaning up disk space..."
    @ansible-playbook -i inventory/production.yml vault-manage.yml -e "vault_action=disk_cleanup"
    @echo "🔄 Step 2: Restarting and unsealing Vault..."
    @ansible-playbook -i inventory/production.yml vault-manage.yml -e "vault_action=restart_unseal" -e "@vars/vault-secrets.yml"
    @echo "✅ Vault recovery complete!"

# ==============================
#       GITHUB RUNNER
# ==============================

# # Configure GitHub runner (set GITHUB_RUNNER_TOKEN env var)
# [group('github-runner')]
# setup:
#     GITHUB_RUNNER_TOKEN="{{ env.GITHUB_RUNNER_TOKEN }}" ansible-playbook -i inventory/production.yml playbooks/github-runner.yml --limit github-runner --extra-vars "ansible_python_interpreter=/usr/bin/python3"

# ==============================
#       TAILSCALE
# ==============================

# Check tailscale status on a host
[group('tailscale')]
tailscale-status host env="production":
    ansible -i inventory/{{ env }}.yml {{ host }} -m shell -a "tailscale status" -b

# ==============================
#       KESTRA
# ==============================

# Restart Kestra service
[group('kestra')]
kestra-restart:
    ansible-playbook -i inventory/production.yml site.yml --tags kestra --limit marcus

# ==============================
#       MONITORING (PROMETHEUS)
# ==============================

# Setup Prometheus monitoring on all production hosts
[group('monitoring')]
monitoring:
    ansible-playbook -i inventory/production.yml site.yml --tags monitoring

# Setup Prometheus monitoring on dev hosts
[group('monitoring')]
monitoring-dev:
    ansible-playbook -i inventory/dev.yml site.yml --tags monitoring

# Setup monitoring on specific host (default: production, add 'dev' for dev hosts)
[group('monitoring')]
monitoring-host host env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --tags monitoring --limit {{ host }}

# Dry run monitoring setup on production
[group('monitoring')]
monitoring-dry:
    ansible-playbook -i inventory/production.yml site.yml --tags monitoring --check

# Dry run monitoring setup on specific host
[group('monitoring')]
monitoring-dry-host host env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --tags monitoring --limit {{ host }} --check

# ==============================
#       KUBERNETES LEARNING
# ==============================

# Deploy a specific K8s resource type (e.g., just k8s-deploy 01-namespace my-namespace)
[group('kubernetes')]
k8s-deploy section namespace="":
    #!/usr/bin/env bash
    if [ -n "{{ namespace }}" ]; then
        ansible-playbook kubernetes/{{ section }}/deploy.yml -e "namespace_name={{ namespace }}"
    else
        ansible-playbook kubernetes/{{ section }}/deploy.yml
    fi

# Dry run K8s deployment
[group('kubernetes')]
k8s-dry section namespace="":
    #!/usr/bin/env bash
    if [ -n "{{ namespace }}" ]; then
        ansible-playbook kubernetes/{{ section }}/deploy.yml -e "namespace_name={{ namespace }}" --check
    else
        ansible-playbook kubernetes/{{ section }}/deploy.yml --check
    fi

# Apply manifests directly with kubectl (skip Ansible)
[group('kubernetes')]
k8s-apply section:
    kubectl apply -f kubernetes/{{ section }}/manifests/

# Delete namespace for a section (cleanup)
[group('kubernetes')]
k8s-clean section:
    @echo "🗑️  Deleting namespace for {{ section }}..."
    @kubectl delete namespace {{ section }} --ignore-not-found=true

## Delete a specific namespace by name
[group('kubernetes')]
k8s-delete-ns namespace:
    @echo "🗑️  Deleting namespace: {{ namespace }}..."
    kubectl delete namespace {{ namespace }}

# View resources in a section's namespace
[group('kubernetes')]
k8s-get section:
    kubectl get all -n {{ section }}

# Describe resources in a section's namespace
[group('kubernetes')]
k8s-describe section resource:
    kubectl describe {{ resource }} -n {{ section }}

# View logs for a pod in a section
[group('kubernetes')]
k8s-logs section pod:
    kubectl logs {{ pod }} -n {{ section }}

# List all K8s sections
[group('kubernetes')]
k8s-list:
    @ls -1 kubernetes/ | grep -E '^[0-9]' | sort

# Deploy all sections in order (full learning path)
[group('kubernetes')]
k8s-all:
    @echo "🚀 Deploying all Kubernetes resources in order..."
    @for section in $(ls -1 kubernetes/ | grep -E '^[0-9]' | sort); do \
        echo "📦 Deploying $${section}..."; \
        ansible-playbook kubernetes/$${section}/deploy.yml || exit 1; \
    done
    @echo "✅ All sections deployed!"

# Clean up all K8s learning namespaces
[group('kubernetes')]
k8s-clean-all:
    @echo "🗑️  Cleaning up all K8s learning namespaces..."
    @for section in $(ls -1 kubernetes/ | grep -E '^[0-9]' | sort); do \
        kubectl delete namespace $${section} --ignore-not-found=true; \
    done
    @echo "✅ Cleanup complete!"
