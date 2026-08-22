# Postgres Backup to GCS

Automated Postgres backup sync to Google Cloud Storage using Ansible playbooks.

## Overview

- **Source**: Local postgres backups at `/var/backup/postgresql/`
- **Destination**: GCS bucket `gs://iv3-infra-us-prod/postgres-backups/`
- **Databases**: n8n, forgejo, kestra, kaneo
- **Retention**: 30 days (configurable)
- **Schedule**: Daily at 03:15 AM via Kestra

## Prerequisites

### 1. GCS Service Account Setup

```bash
# On the postgres host (bellamy)
sudo mkdir -p /root/.gcp
sudo cp ~/path/to/terraform-key.json /root/.gcp/
sudo chmod 600 /root/.gcp/terraform-key.json
```

### 2. Install google-cloud-sdk

**On NixOS (add to configuration.nix):**
```nix
environment.systemPackages = with pkgs; [
  google-cloud-sdk
];
```

**Or via nixos-config:**
Already included if you're using the GCP modules.

### 3. Verify gsutil works

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/root/.gcp/terraform-key.json
gsutil ls gs://iv3-infra-us-prod/
```

## Usage

### Backup Sync (Upload to GCS)

```bash
# From playbooks directory
cd /home/thein3rovert/Documents/project/playbooks

# Run backup sync
ansible-playbook playbooks/postgres-backup-sync.yml

# Dry run (check mode)
ansible-playbook playbooks/postgres-backup-sync.yml --check

# Custom retention (7 days instead of 30)
ansible-playbook playbooks/postgres-backup-sync.yml -e "retention_days=7"
```

### Restore from GCS

⚠️ **WARNING**: Restore will DROP and recreate the database!

```bash
# Restore latest backup for n8n database
ansible-playbook playbooks/postgres-backup-restore.yml -e "database=n8n"

# Restore specific database
ansible-playbook playbooks/postgres-backup-restore.yml -e "database=forgejo"

# Dry run first
ansible-playbook playbooks/postgres-backup-restore.yml -e "database=n8n" --check
```

## Kestra Integration

### Kestra Workflow (Example)

```yaml
id: postgres-backup-sync
namespace: homelab.backups

triggers:
  - id: daily-schedule
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "15 3 * * *"

tasks:
  - id: run-ansible-backup
    type: io.kestra.plugin.scripts.shell.Commands
    commands:
      - cd /home/thein3rovert/Documents/project/playbooks
      - ansible-playbook playbooks/postgres-backup-sync.yml

  - id: send-alert-on-failure
    type: io.kestra.plugin.notifications.slack.SlackIncomingWebhook
    url: "{{ secret('SLACK_WEBHOOK_URL') }}"
    payload: |
      {
        "text": "❌ Postgres backup sync failed!"
      }
    condition: "{{ parent.status == 'FAILED' }}"
```

## Monitoring

### Check Recent Backups

```bash
# List backups in GCS
gsutil ls -lh gs://iv3-infra-us-prod/postgres-backups/

# List backups older than 30 days
gsutil ls -l gs://iv3-infra-us-prod/postgres-backups/ | \
  awk '$2 < "'$(date -d '30 days ago' +%Y-%m-%d)'" {print $3}'
```

### Verify Backup Integrity

```bash
# Download and test a backup
gsutil cp gs://iv3-infra-us-prod/postgres-backups/n8n.sql.gz /tmp/
gunzip /tmp/n8n.sql.gz
head -20 /tmp/n8n.sql  # Should show SQL commands
```

## Troubleshooting

### Error: "gsutil not found"

Install google-cloud-sdk on the target host:
```bash
nix-env -iA nixos.google-cloud-sdk
```

### Error: "Service account key not found"

Ensure the key is at `/root/.gcp/terraform-key.json`:
```bash
sudo ls -l /root/.gcp/terraform-key.json
```

### Error: "Permission denied" on GCS

Verify service account has Storage Object Admin role:
```bash
# From GCP Console → IAM
# Or via gcloud
gcloud projects get-iam-policy thein3rovertproject | grep terraform
```

### No backups found in last 24 hours

Check if postgres backup service is running:
```bash
systemctl status postgresqlBackup.service
ls -lh /var/backup/postgresql/
```

## Backup Structure

```
gs://iv3-infra-us-prod/
└── postgres-backups/
    ├── n8n.sql.gz
    ├── forgejo.sql.gz
    ├── kestra.sql.gz
    └── kaneo.sql.gz
```

**Flat structure**: Latest backup overwrites previous with same name
**Retention**: Files older than 30 days are automatically deleted

## Security

- ✅ Service account key stored with 600 permissions
- ✅ GCS bucket has uniform bucket-level access
- ✅ Public access prevention enabled
- ✅ 7-day soft delete policy for recovery
- ✅ Backups stored in regional us-central1 (free tier)

## Cost Estimate

- Storage: <100MB × 30 days = <3GB (well within 5GB free tier)
- Operations: ~30 writes/month + ~30 deletes/month = ~60 ops (well within free tier)
- **Monthly cost: $0.00** ✅

## Support

For issues or questions:
1. Check playbook output: `ansible-playbook ... -v`
2. Review Kestra logs (if using Kestra)
3. Check GCS bucket contents: `gsutil ls gs://iv3-infra-us-prod/postgres-backups/`
