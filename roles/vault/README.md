# Vault Management Role

Manages HashiCorp Vault operations including restart, unseal, status checks, and disk cleanup.

## Features

- ✅ Restart Vault service with auto-enable on boot
- 🔓 Unseal Vault with secure key management
- 🔄 Combined restart + unseal in one operation
- 📊 Status and health checks
- 🧹 Disk cleanup to prevent storage issues
- ⚙️ Automatic journald configuration to prevent log buildup
- 🔍 Hourly disk monitoring with auto-cleanup
- ♻️ **Reusable design** - Uses generic `systemd` role for service management

## Architecture

This role follows **modular design principles**:

```
vault role
├── Service Management → Delegates to systemd role (reusable)
├── Vault-specific logic → unseal, status checks (unique)
└── Disk management → cleanup tasks (could be extracted)
```

### Why This Matters

**Before**: Each role duplicated systemd operations
```yaml
# Duplicated in vault, backup, traefik, etc.
- name: Restart service
  systemd: name=myservice state=restarted
- name: Enable service  
  systemd: name=myservice enabled=true
- name: Wait for port
  wait_for: port=8080
```

**After**: Single source of truth
```yaml
# Vault role calls systemd role
- include_role: 
    name: systemd
  vars:
    systemd_service_name: vault
    systemd_service_state: restarted
    systemd_service_enabled: true
    systemd_wait_for_port: 8200
```

### Benefits

- ✅ **DRY**: No code duplication
- ✅ **Consistency**: Same behavior across all services  
- ✅ **Testability**: Test systemd logic once
- ✅ **Maintainability**: Update in one place
- ✅ **Composability**: Mix and match roles

## Usage

### Check Vault Status
```bash
cd /home/thein3rovert/Documents/project/playbooks
ansible-playbook vault-manage.yml -e "vault_action=status"
```

### Restart Vault Only
```bash
ansible-playbook vault-manage.yml -e "vault_action=restart"
```

### Unseal Vault (assumes already running)
```bash
ansible-playbook vault-manage.yml -e "vault_action=unseal" --ask-vault-pass
```

### Restart + Unseal (most common for recovery)
```bash
ansible-playbook vault-manage.yml -e "vault_action=restart_unseal" --ask-vault-pass
```

### Disk Cleanup (run if disk is full)
```bash
ansible-playbook vault-manage.yml -e "vault_action=disk_cleanup"
```

## Storing Unseal Keys Securely

### Option 1: Encrypted Ansible Vault File (Recommended)

1. Create encrypted vault file:
```bash
cp vars/vault-secrets.yml.example vars/vault-secrets.yml
ansible-vault encrypt vars/vault-secrets.yml
# Enter a password when prompted
```

2. Edit the encrypted file with your real keys:
```bash
ansible-vault edit vars/vault-secrets.yml
```

3. Use in playbook:
```bash
ansible-playbook vault-manage.yml -e "vault_action=restart_unseal" --ask-vault-pass
```

### Option 2: Pass Keys via Command Line (Less Secure)

```bash
ansible-playbook vault-manage.yml \
  -e "vault_action=restart_unseal" \
  -e "vault_unseal_keys=['key1','key2','key3']"
```

## Variables

Set in `defaults/main.yml`:
- `vault_addr`: Vault API address (default: `http://127.0.0.1:8200`)
- `vault_config_path`: Vault config file location
- `vault_service_name`: Systemd service name (default: `vault`)
- `vault_unseal_keys`: List of unseal keys (provide via vars or extra-vars)

## Dependencies

- **systemd role**: For service management operations
  - Used by: `restart.yml`, `restart_and_unseal.yml`
  - Provides: start/stop/restart/enable, port waiting

## Task Files

| File | Purpose | Uses systemd role? |
|------|---------|-------------------|
| `main.yml` | Task router | No |
| `restart.yml` | Restart service | ✅ Yes |
| `unseal.yml` | Unseal only | No |
| `restart_and_unseal.yml` | Combined operation | ✅ Yes |
| `status.yml` | Health checks | No |
| `disk_cleanup.yml` | Disk management | No |

## Extending This Pattern

Want to create a new service management role? Follow this pattern:

```yaml
# roles/myapp/tasks/restart.yml
- name: Restart myapp service
  ansible.builtin.include_role:
    name: systemd
  vars:
    systemd_service_name: myapp
    systemd_service_state: restarted
    systemd_service_enabled: true
    systemd_wait_for_port: 3000  # If app has a port
```

## Requirements

- HashiCorp Vault installed on target host
- Vault CLI available in PATH
- Root/sudo access for service management
- **systemd role** available in `roles/systemd/`
