# Vault Server Recovery Guide

## 🔍 Root Cause Analysis

**Issue**: Vault service keeps dying randomly, requiring manual restart and unseal.

**Root Cause**: **Disk space exhaustion** (97% full → only 71MB free on 2GB partition)

### What Was Causing the Disk Issues:
- `/var/log/journal`: 154MB of systemd logs
- `/var/cache`: 134MB of apt package cache  
- Small 2GB root partition on becca

### Why Vault Died:
Vault uses Raft storage at `/opt/vault/data`. When disk space runs out, Raft cannot write new data, causing Vault to crash or become unresponsive.

## ✅ Fixes Applied

### 1. Immediate Cleanup (Applied on 2026-07-04)
- ✅ Cleaned systemd journal logs (freed 100MB)
- ✅ Cleaned apt cache
- ✅ Removed old compressed logs
- ✅ Enabled Vault service to auto-start on boot
- ✅ Configured journald to limit log size permanently
- ✅ Installed hourly disk monitoring cron job

**Result**: Disk usage reduced from 97% → 89%

### 2. Preventive Measures
- **Journald limits**: Max 50MB, keep 200MB free, 7-day retention
- **Hourly monitoring**: Auto-cleanup triggers at 85% disk usage
- **Service auto-start**: Vault now enabled in systemd

## 📋 Quick Commands

```bash
cd /home/thein3rovert/Documents/project/playbooks

# Check Vault status
just vault-status

# Full recovery (cleanup + restart + unseal)
just vault-recover

# Individual operations
just vault-restart              # Restart only
just vault-disk-cleanup         # Clean disk space
just vault-restart-unseal       # Restart and unseal
```

## 🔐 Setting Up Unseal Keys

### First Time Setup

1. Create encrypted vault file with your unseal keys:
```bash
cd /home/thein3rovert/Documents/project/playbooks
cp vars/vault-secrets.yml.example vars/vault-secrets.yml
nano vars/vault-secrets.yml  # Add your 3 unseal keys
ansible-vault encrypt vars/vault-secrets.yml
```

2. Supply the existing password with `--ask-vault-pass`, or set
   `ANSIBLE_VAULT_PASSWORD_FILE` to a protected password-client script or file
   stored outside this repository.

### Usage After Setup

All unseal operations will work automatically:
```bash
just vault-restart-unseal    # Uses encrypted keys automatically
just vault-recover           # Full recovery with auto-unseal
```

## 🚨 Emergency Recovery Procedure

If Vault dies again:

```bash
# Option 1: Full automated recovery
just vault-recover

# Option 2: Manual step-by-step
just vault-disk-cleanup       # Free up space first
just vault-restart            # Start Vault
# Then manually unseal via SSH or use:
just vault-unseal
```

## 📊 Monitoring Commands

```bash
# Check disk space
ssh becca "df -h / && du -sh /opt/vault/* && journalctl --disk-usage"

# Check Vault status
ssh becca "systemctl status vault && export VAULT_ADDR='http://127.0.0.1:8200' && vault status"

# Check logs
ssh becca "journalctl -u vault -n 50"
```

## 🔄 How Auto-Cleanup Works

The system now has automatic protection:

1. **Journald limits** (`/etc/systemd/journald.conf`):
   - Max journal size: 50MB
   - Keep free space: 200MB
   - Retention: 7 days

2. **Hourly monitoring** (`/usr/local/bin/vault-disk-check.sh`):
   - Runs every hour via cron
   - Checks disk usage
   - Auto-cleans if > 85% full

3. **Service auto-start**:
   - Vault now enabled in systemd
   - Will restart automatically on boot

## 🎯 Long-Term Solution

Consider one of these options:

### Option 1: Expand Disk (Recommended)
Expand the becca VM disk from 2GB to 5GB or 10GB in Proxmox.

### Option 2: Auto-Unseal
Set up auto-unseal using:
- Transit secrets engine (requires another Vault)
- Cloud KMS (AWS, Azure, GCP)

### Option 3: Dedicated Partition
Move `/var/log` or `/opt/vault` to a separate partition.

## 📝 Files Created

- `/home/thein3rovert/Documents/project/playbooks/vault-manage.yml` - Main playbook
- `/home/thein3rovert/Documents/project/playbooks/roles/vault/` - Complete role with tasks
- `/home/thein3rovert/Documents/project/playbooks/vars/vault-secrets.yml.example` - Template for keys
- Updated justfile with 6 new `vault-*` commands

## ⚙️ Server Configuration Applied

On becca (10.10.10.101):
- `/etc/systemd/journald.conf` - Log size limits
- `/usr/local/bin/vault-disk-check.sh` - Monitoring script
- Root crontab - Hourly disk check job
- Systemd - Vault service enabled

## 🔧 Troubleshooting

### "vault: command not found"
The vault CLI needs to be in PATH. Check with: `ssh becca "which vault"`

### Unseal fails with "permission denied"
Ensure `vars/vault-secrets.yml` is encrypted and provide the Vault password
interactively or through an external password client.

### Playbook can't connect to becca
Check SSH config: `ssh becca "hostname"` should work first.

### Disk fills up again quickly
Run: `ssh becca "du -sh /* | sort -hr"` to find what's growing.

---

**Last Updated**: 2026-07-04  
**Status**: ✅ Fixed and automated  
**Next Check**: Monitor disk usage over next week
