# Postgres GCS Backup Role

Syncs Postgres backups from local storage to Google Cloud Storage.

## Requirements

- `google-cloud-sdk` package (for `gsutil`)
- GCS service account key with Storage Object Admin permissions
- Local postgres backups at `/var/backup/postgresql/`

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# Source directory for postgres backups
backup_source_dir: "/var/backup/postgresql"

# GCS configuration
gcs_bucket: "iv3-infra-us-prod"
gcs_prefix: "postgres-backups"

# Retention in days
retention_days: 30

# Service account key location
service_account_key: "/root/.gcp/terraform-key.json"

# Databases to backup
postgres_databases:
  - n8n
  - forgejo
  - kestra
  - kaneo

# Fail if no recent backups found
fail_on_missing_backups: true

# Age threshold for "recent" backups (in days)
backup_age_threshold: 1
```

## Dependencies

None

## Example Playbook

### Basic usage

```yaml
---
- name: Sync Postgres Backups to GCS
  hosts: bellamy
  become: true
  
  roles:
    - postgres-gcs-backup
```

### With custom variables

```yaml
---
- name: Sync Postgres Backups to GCS
  hosts: bellamy
  become: true
  
  roles:
    - role: postgres-gcs-backup
      vars:
        retention_days: 7
        gcs_prefix: "postgres-backups-dev"
```

### Using tags (in site.yml)

```yaml
- name: Run Postgres GCS Backup Role
  ansible.builtin.import_role:
    name: postgres-gcs-backup
  tags:
    - postgres-backup
    - backup
```

## Usage

```bash
# Run the role
ansible-playbook site.yml --tags postgres-backup

# Or create a dedicated playbook
ansible-playbook playbooks/postgres-backup-sync.yml

# Dry run
ansible-playbook playbooks/postgres-backup-sync.yml --check

# Override retention
ansible-playbook playbooks/postgres-backup-sync.yml -e "retention_days=7"
```

## License

MIT

## Author

thein3rovert
