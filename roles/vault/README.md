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

## Preventing Disk Issues

The disk cleanup action:
- Cleans systemd journal logs (keeps 50MB)
- Removes old compressed logs
- Configures journald limits permanently
- Sets up hourly monitoring cron job

Run after Vault failure:
```bash
ansible-playbook vault-manage.yml -e "vault_action=disk_cleanup"
ansible-playbook vault-manage.yml -e "vault_action=restart_unseal" --ask-vault-pass
```

## Root Cause Analysis

Your Vault was dying due to **disk space exhaustion** (97% full). The main culprits:
- `/var/log/journal`: 154MB of systemd logs
- `/var/cache`: 134MB of apt cache
- Small 2GB root partition

The disk cleanup role prevents this by:
1. Limiting journal to 50MB max
2. Keeping 200MB free always
3. Rotating logs after 7 days
4. Hourly monitoring and auto-cleanup at 85% threshold

## Variables

Set in `defaults/main.yml`:
- `vault_addr`: Vault API address (default: `http://127.0.0.1:8200`)
- `vault_config_path`: Vault config file location
- `vault_service_name`: Systemd service name (default: `vault`)
- `vault_unseal_keys`: List of unseal keys (provide via vars or extra-vars)

## Tags

- `status`: Check Vault and service status
- `restart`: Restart Vault service
- `unseal`: Unseal Vault
- `restart_unseal`: Restart and unseal in one operation
- `disk_cleanup`: Clean up disk space

## Requirements

- HashiCorp Vault installed on target host
- Vault CLI available in PATH
- Root/sudo access for service management
