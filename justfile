# Ansible Playbook Runner

# Show all commands
default:
    @just --list

# ==============================
#       PLAYBOOK EXECUTION
# ==============================

# Run all playbooks on production
[group('playbooks')]
all:
    ansible-playbook -i inventory/production.yml site.yml --ask-become-pass --ask-vault-pass

# Run all playbooks on dev
[group('playbooks')]
all-dev:
    ansible-playbook -i inventory/dev.yml site.yml --ask-become-pass --ask-vault-pass

# Run on specific host
[group('playbooks')]
host hostname env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --limit {{ hostname }} --ask-become-pass --ask-vault-pass

# ==============================
#       ROLES
# ==============================

# Run a specific role on production
[group('roles')]
run role:
    ansible-playbook -i inventory/production.yml site.yml --tags {{ role }} --ask-become-pass --ask-vault-pass

# Run a specific role on dev
[group('roles')]
run-dev role:
    ansible-playbook -i inventory/dev.yml site.yml --tags {{ role }} --ask-become-pass --ask-vault-pass

# Run a specific role on a specific host
[group('roles')]
run-host role host env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --tags {{ role }} --limit {{ host }} --ask-become-pass --ask-vault-pass

# ==============================
#       DRY RUN
# ==============================

# Dry run all playbooks on production
[group('dry-run')]
dry-all:
    ansible-playbook -i inventory/production.yml site.yml --check --ask-vault-pass

# Dry run all playbooks on dev
[group('dry-run')]
dry-all-dev:
    ansible-playbook -i inventory/dev.yml site.yml --check --ask-vault-pass

# Dry run on specific host
[group('dry-run')]
dry-host hostname env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --limit {{ hostname }} --check --ask-vault-pass

# Dry run a specific role on production
[group('dry-run')]
dry-run role:
    ansible-playbook -i inventory/production.yml site.yml --tags {{ role }} --check --ask-vault-pass

# Dry run a specific role on dev
[group('dry-run')]
dry-run-dev role:
    ansible-playbook -i inventory/dev.yml site.yml --tags {{ role }} --check --ask-vault-pass

# Dry run a specific role on a specific host
[group('dry-run')]
dry-run-host role host env="production":
    ansible-playbook -i inventory/{{ env }}.yml site.yml --tags {{ role }} --limit {{ host }} --check --ask-vault-pass

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
    ansible-playbook -i inventory/{{ env }}.yml site.yml --syntax-check --ask-vault-pass

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
