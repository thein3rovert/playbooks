# Ansible Playbook Runner
# 
# Authentication: Vault password stored in .vault_pass (gitignored)
#                 Become password stored in vars/vault.yml
#                 No password prompts required
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
#       VAULT
# ==============================

# Manage vault
[group('vault')]
edit:
    ansible-vault edit vars/vault.yml

# Change password and re-encrypt vault
[group('vault')]
rekey:
    ansible-vault rekey vars/vault.yml

# ==============================
#       GITHUB RUNNER
# ==============================

# Configure GitHub runner (set GITHUB_RUNNER_TOKEN env var)
[group('github-runner')]
setup:
    GITHUB_RUNNER_TOKEN="{{ env.GITHUB_RUNNER_TOKEN }}" ansible-playbook -i inventory/production.yml playbooks/github-runner.yml --limit github-runner --extra-vars "ansible_python_interpreter=/usr/bin/python3"
