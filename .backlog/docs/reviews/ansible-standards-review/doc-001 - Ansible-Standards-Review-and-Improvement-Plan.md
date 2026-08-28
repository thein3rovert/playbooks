---
id: doc-001
title: Ansible Standards Review and Improvement Plan
type: specification
created_date: '2026-08-28 21:24'
tags:
  - ansible
  - review
  - security
  - best-practices
---
# Ansible Standards Review and Improvement Plan

## Overall assessment

The project has a good role-based foundation, uses FQCNs in many newer tasks, and generally favors declarative Kubernetes modules. However, security, host targeting, idempotency, dependency management, and automated validation need improvement before the repository consistently follows modern Ansible standards.

## Immediate security improvements

### Vault password handling

**Where:** `.vault_pass`, `ansible.cfg`

**Problem:** A plaintext Vault password exists in the working directory and `ansible.cfg` references it automatically.

**Improve:** Rotate the password and replace the static file with a Vault password client script or secret-manager integration. Confirm it has not leaked through backups or workstation synchronization.

### Tailscale authentication key

**Where:** `roles/tailscale/tasks/main.yml`

**Problem:** The key is passed in command arguments with logging enabled, and reusable keys may be generated on every run.

**Improve:** Use `no_log: true`, generate a key only when enrollment is required, prefer short-lived/non-reusable keys, and avoid command-line secret exposure where possible.

### Argo CD administrator password

**Where:** `roles/argocd/tasks/main.yml`

**Problem:** The initial administrator password is decoded and printed with `debug`.

**Improve:** Remove password output and provide only secure retrieval instructions or store it through an approved secret workflow.

### Linkding default password

**Where:** `roles/linkding/defaults/main.yml`, `roles/linkding/tasks/main.yml`

**Problem:** The role deploys with a usable `changeme` default.

**Improve:** Remove the default and assert that the password is defined, nonempty, and not a known placeholder.

### SSH host-key checking

**Where:** `ansible.cfg`

**Problem:** `host_key_checking = False` allows silent host-key changes and man-in-the-middle attacks.

**Improve:** Enable host-key checking and manage `known_hosts` explicitly.

## Reliability and correctness

### Overly broad host targeting

**Where:** `site.yml`

**Problem:** Many incompatible roles run against `hosts: all`, despite a mixture of Debian and NixOS systems.

**Improve:** Create platform and function groups such as `debian_hosts`, `nixos_hosts`, `backup_targets`, `monitoring_targets`, `k3s_servers`, and `github_runners`. Split the site playbook into narrowly targeted plays.

### Missing SSH handler

**Where:** `roles/user/tasks/main.yml`

**Problem:** Tasks notify `Restart ssh`, but the role has no matching handler. SSH is hardened without configuration validation or a safe connectivity check.

**Improve:** Add a platform-aware handler, validate using `sshd -t`, flush the handler safely, and verify alternate login access before ending the play.

### Broken Nix role logic

**Where:** `roles/nix/tasks/main.yml`

**Problem:** Registered variable names are inconsistent, one expression uses a hyphen instead of an underscore, and a `when` condition is nested incorrectly.

**Improve:** Correct `nix_installer_result` references, use `nix_receipt`, move `when` to task level, and test both first installation and repeat execution.

### Linkding is not convergent

**Where:** `roles/linkding/tasks/main.yml`

**Problem:** Most resources are applied only when the Deployment does not exist, so later configuration changes are ignored.

**Improve:** Always apply desired Kubernetes resources using declarative modules and allow Ansible to determine whether changes are needed.

### Standalone role resolution

**Where:** `playbooks/postgres-backup-sync.yml`, `roles/github-runner/github-runner.yml`, `ansible.cfg`

**Problem:** Standalone playbooks cannot resolve local roles, and one playbook is incorrectly stored inside a role.

**Improve:** Move playbooks into `playbooks/` and configure `roles_path` or use a consistent repository layout.

### K3s report aggregation

**Where:** `roles/k3s-inventory/tasks/`

**Problem:** Each host builds a local report, while a `run_once` summary expects combined data.

**Improve:** Aggregate through `hostvars`, delegated facts, or controller-side accumulation before rendering the report.

## Backup improvements

### Incomplete archives may appear successful

**Where:** `roles/backup/tasks/backup-single.yml`

**Problem:** `tar --ignore-failed-read` can omit unreadable files without failing the backup.

**Improve:** Fail on unreadable data unless explicitly excluded, validate archive integrity, verify the remote upload, and compare checksums where supported.

### Cleanup is not guaranteed

**Where:** `roles/backup/tasks/main.yml`, `roles/postgres-gcs-backup/tasks/main.yml`

**Problem:** Temporary data remains when an earlier task fails.

**Improve:** Wrap operations in `block` with cleanup under `always`.

### Unsafe shell usage

**Where:** `roles/backup/tasks/`

**Problem:** Paths are interpolated into shell commands and several modules do not use FQCNs.

**Improve:** Prefer Ansible modules or `command` with `argv`; quote unavoidable shell inputs and use `ansible.builtin.*` consistently.

### GCS authentication and verification

**Where:** `roles/postgres-gcs-backup/tasks/`

**Problem:** The prepared credential environment is unused, and verification may check the wrong filename or accept a stale object.

**Improve:** Apply the credential environment to GCS tasks and verify every exact uploaded object from the current run.

## Idempotency and reproducibility

### Mutable downloads and versions

**Where:** Tailscale, Helm, Nix, Linkding, Longhorn, and Argo CD roles

**Problem:** Mutable install scripts, `latest`, `latest-plus`, and `stable` reduce reproducibility.

**Improve:** Pin versions and checksums; pin container digests when practical. Avoid downloading and executing mutable scripts as root.

### Error suppression

**Where:** Longhorn, systemd, and K3s inventory roles

**Problem:** Broad `ignore_errors` and `failed_when: false` can hide real failures.

**Improve:** Define accepted return codes explicitly and fail for unexpected conditions.

### Handler consistency

**Where:** `roles/prometheus/tasks/main.yml`

**Problem:** Service reloads and restarts are implemented as ordinary conditional tasks and may happen more than once.

**Improve:** Notify handlers for daemon reload and service restart so changes are consolidated.

## Variables and inventory

### Variable namespacing

**Where:** Multiple role defaults and tasks

**Problem:** Generic variables such as `default_user`, `retention_days`, and `db_port` can collide.

**Improve:** Prefix public role variables, for example `backup_retention_days` and `postgres_gcs_backup_service_account_key`. Add `meta/argument_specs.yml` for validation.

### Inventory consistency

**Where:** `inventory/group_vars/`, `inventory/host_vars/`

**Problem:** Environment variable names differ, file modes may parse as decimal numbers, and stale host variable files and a backup inventory remain.

**Improve:** Standardize names such as `environment_name`, quote modes like `'0700'`, delete or archive stale files, and remove `hosts.yml.bak` from the active repository.

### Python interpreter

**Where:** `ansible.cfg`, NixOS host variables

**Problem:** A global `/usr/bin/python3` conflicts with systems that use nonstandard interpreter paths.

**Improve:** Use automatic interpreter discovery globally and override only exceptional hosts or groups.

### Privilege escalation

**Where:** `site.yml`, standalone playbooks, production inventory

**Problem:** Entire plays run with `become: true`, and some hosts connect directly as root.

**Improve:** Connect as a non-root account, escalate only on tasks or roles that require it, and maintain controlled sudo rules.

## Tooling and quality gates

### Dependencies

**Problem:** Collections, Python dependencies, and supported Ansible versions are not declared.

**Improve:** Add `requirements.yml` for collections, pin controller dependencies, and document the supported `ansible-core` version or provide an execution environment.

### Linting and CI

**Problem:** There is no `.ansible-lint`, `.yamllint`, syntax-check CI, Molecule scenario, or idempotence test.

**Improve:** Add CI that installs pinned dependencies and runs YAML lint, Ansible lint, inventory parsing, and syntax checks. Add check-mode/idempotence tests for high-risk roles.

### GitHub workflow

**Where:** `.github/workflows/rebase-on-tag.yml`

**Problem:** It uses an older checkout action, a PAT, broad permissions, and force-rebases branches while providing no Ansible validation.

**Improve:** Upgrade maintained actions, declare least-privilege permissions, prefer `GITHUB_TOKEN`, and reconsider automatic branch rewriting.

## Recommended order of work

1. Rotate exposed credentials and stop all secret logging.
2. Remove default passwords and add secret assertions.
3. Repair the Nix role and SSH handler.
4. Split `site.yml` by platform and host function.
5. Enable SSH host-key checking.
6. Add pinned dependencies, lint configuration, and validation CI.
7. Fix role/playbook layout and role resolution.
8. Make Linkding fully convergent and enable secure Argo CD TLS.
9. Strengthen backup integrity, verification, and guaranteed cleanup.
10. Namespace role variables and add argument specifications.
11. Pin installers, charts, and images.
12. Add check-mode and second-run idempotence tests.

## Suggested target structure

```text
.
├── ansible.cfg
├── requirements.yml
├── requirements-dev.txt
├── .ansible-lint
├── .yamllint
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   ├── group_vars/
│   │   └── host_vars/
│   └── development/
│       ├── hosts.yml
│       ├── group_vars/
│       └── host_vars/
├── playbooks/
│   ├── site.yml
│   ├── base.yml
│   ├── monitoring.yml
│   ├── kubernetes.yml
│   ├── backups.yml
│   ├── github-runner.yml
│   └── vault-manage.yml
├── roles/
│   └── ROLE_NAME/
│       ├── defaults/main.yml
│       ├── handlers/main.yml
│       ├── meta/main.yml
│       ├── meta/argument_specs.yml
│       ├── tasks/main.yml
│       ├── templates/
│       └── README.md
├── tests/
└── .github/workflows/ansible-ci.yml
```

## Existing strengths to preserve

- Clear role separation in most areas.
- Frequent use of FQCNs in newer content.
- Declarative Kubernetes and Helm modules.
- `changed_when: false` on several read-only probes.
- `no_log: true` for Linkding Secret creation and Vault unseal operations.
- Pinned and checksum-validated GitHub Runner downloads.
- Separate production and development inventories.
- Useful role-level tags in the main playbook.
