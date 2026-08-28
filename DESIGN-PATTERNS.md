# Ansible Role Design Patterns

Design principles and patterns for creating reusable, maintainable Ansible roles.

## Core Principles

1. **DRY (Don't Repeat Yourself)** - Extract common functionality into reusable roles
2. **Single Responsibility** - Each role should do one thing well
3. **Composition Over Duplication** - Use `include_role` to compose functionality
4. **Clear Dependencies** - Document role dependencies explicitly

## Pattern 1: Generic Infrastructure Roles

Create roles that handle infrastructure primitives that many applications need.

### Example: systemd Role

**Purpose**: Manage ANY systemd service (not just one specific service)

**Design**:
```yaml
# roles/systemd/tasks/main.yml
- name: Manage systemd service
  ansible.builtin.systemd:
    name: "{{ systemd_service_name }}"
    state: "{{ systemd_service_state }}"
    enabled: "{{ systemd_service_enabled }}"
  become: true
  when: systemd_service_name != ""
```

**Usage by other roles**:
```yaml
# roles/vault/tasks/restart.yml
- name: Restart Vault service
  ansible.builtin.include_role:
    name: systemd
  vars:
    systemd_service_name: vault
    systemd_service_state: restarted
    systemd_service_enabled: true
    systemd_wait_for_port: 8200
```

### Candidates for Generic Roles

Based on your current setup, consider extracting:

| Common Task | Generic Role | Used By |
|-------------|-------------|---------|
| ✅ Systemd management | `systemd` | vault, traefik, tailscale, backup |
| 🔄 Disk space checks | `disk-management` | vault, backup, any storage-heavy app |
| 🔄 Log rotation | `log-management` | all servers |
| 🔄 Firewall rules | `firewall` | any service with ports |
| 🔄 TLS certificates | `tls` | traefik, nginx, vault |
| 🔄 Backup operations | `backup-core` | vault, databases, configs |
| 🔄 Health checks | `healthcheck` | all services |

## Pattern 2: Application-Specific Roles

These roles focus on application-specific logic and delegate infrastructure tasks to generic roles.

### Structure

```
roles/myapp/
├── defaults/
│   └── main.yml          # App-specific defaults
├── handlers/
│   └── main.yml          # App-specific handlers
├── tasks/
│   ├── main.yml          # Task router
│   ├── install.yml       # App installation
│   ├── configure.yml     # App configuration
│   ├── manage.yml        # Calls systemd role
│   └── healthcheck.yml   # App health verification
├── templates/
│   └── app.conf.j2       # App config templates
└── README.md
```

### Example: Vault Role

**What it does**:
- ✅ Vault-specific: unseal logic, Vault CLI commands, Raft configuration
- ❌ Not Vault-specific: systemd operations (delegates to systemd role)

```yaml
# roles/vault/tasks/restart_and_unseal.yml

# Vault-specific: disk check with Vault context
- name: Check disk space before restart
  ansible.builtin.shell: df / | tail -1 | awk '{print $5}' | sed 's/%//'
  register: disk_usage

# Generic: delegate to systemd role
- name: Restart Vault service
  ansible.builtin.include_role:
    name: systemd
  vars:
    systemd_service_name: vault
    systemd_service_state: restarted
    systemd_service_enabled: true
    systemd_wait_for_port: 8200

# Vault-specific: unseal operation
- name: Unseal Vault with keys
  ansible.builtin.command: "vault operator unseal {{ item }}"
  loop: "{{ vault_unseal_keys }}"
  no_log: true
```

## Pattern 3: Role Composition

Build complex operations by composing simple roles.

### Before (Monolithic)
```yaml
roles/backup/tasks/main.yml:
  - Check disk space (duplicated)
  - Stop service (systemd - duplicated)
  - Run backup (unique)
  - Start service (systemd - duplicated)
  - Check disk space again (duplicated)
  - Clean old backups (duplicated)
```

### After (Composed)
```yaml
roles/backup/tasks/main.yml:
  - include_role: name=disk-management vars={action: check}
  - include_role: name=systemd vars={service: myapp, state: stopped}
  - name: Run backup (unique backup logic)
  - include_role: name=systemd vars={service: myapp, state: started}
  - include_role: name=disk-management vars={action: cleanup}
```

## Pattern 4: Variable Hierarchy

Design variables for composability:

```yaml
# Generic role defaults (roles/systemd/defaults/main.yml)
systemd_service_name: ""              # Must be provided
systemd_service_state: started        # Sensible default
systemd_service_enabled: true         # Opinionated default

# Application role defaults (roles/vault/defaults/main.yml)
vault_service_name: vault             # App-specific
vault_addr: http://127.0.0.1:8200    # App-specific

# Application role calls generic role
- include_role: name=systemd
  vars:
    systemd_service_name: "{{ vault_service_name }}"  # Pass through
```

## Pattern 5: Role Dependencies

Document dependencies explicitly in role README:

```markdown
## Dependencies

- **systemd role**: For service management
  - Used by: `restart.yml`, `start.yml`
  - Provides: service start/stop/restart, enable/disable
  
- **disk-management role**: For disk space checks
  - Used by: `backup.yml`, `cleanup.yml`  
  - Provides: disk usage checks, cleanup operations
```

## Refactoring Checklist

When you find duplicated logic:

1. ✅ **Identify duplication**: Find repeated patterns across roles
2. ✅ **Extract to generic role**: Create a parameterized role
3. ✅ **Update consumers**: Refactor existing roles to use generic role
4. ✅ **Document dependencies**: Update README files
5. ✅ **Test**: Verify existing functionality still works
6. ✅ **Remove old code**: Delete duplicated tasks

## Real-World Example: Systemd Refactoring

### What We Did (2026-07-04)

**Found duplication**:
- vault role: systemd restart + enable + wait
- backup role: (likely) systemd operations
- traefik role: hardcoded systemd tasks
- tailscale role: hardcoded systemd tasks

**Created generic role**:
- `roles/systemd/` - handles ANY service
- Variables: service_name, state, enabled, wait_for_port

**Refactored consumers**:
- vault role now calls systemd role
- 15 lines of code → 6 lines
- Added port waiting feature for free

**Benefits**:
- ✅ Vault restart code: 15 lines → 6 lines (60% reduction)
- ✅ Consistency across all service restarts
- ✅ Easy to add new services
- ✅ Single place to fix systemd bugs

## Next Refactoring Opportunities

### 1. Disk Management Role

**Current state**: Duplicated disk checks in vault, backup
**Proposed**:
```yaml
roles/disk-management/tasks/main.yml:
  - check_usage.yml    # Check disk usage
  - cleanup.yml        # Clean logs, cache, temp
  - monitor.yml        # Install monitoring cron
```

### 2. Log Management Role

**Current state**: Journal cleanup in vault, possibly others
**Proposed**:
```yaml
roles/log-management/tasks/main.yml:
  - configure_journald.yml  # Set journal limits
  - rotate_logs.yml         # Rotate application logs
  - cleanup_old_logs.yml    # Remove old logs
```

### 3. Backup Core Role

**Current state**: Backup logic possibly duplicated
**Proposed**:
```yaml
roles/backup-core/tasks/main.yml:
  - pre_backup.yml   # Stop services, check disk
  - backup.yml       # Generic backup with rsync/rclone
  - post_backup.yml  # Start services, verify
```

## Anti-Patterns to Avoid

❌ **Overly generic roles**: Don't create a "do everything" role
❌ **Hidden dependencies**: Don't assume other roles exist
❌ **Tight coupling**: Don't hardcode role names in tasks
❌ **No documentation**: Always document role purpose and usage
❌ **Breaking changes**: Maintain backwards compatibility when refactoring

## Questions to Ask

When creating or refactoring a role, ask:

1. **Is this logic specific to one application?** → Keep in app role
2. **Could this be used by other apps?** → Extract to generic role
3. **Does this role do more than one thing?** → Consider splitting
4. **Are there duplicated tasks?** → Refactor
5. **Is the interface clear?** → Document variables

## Summary

**Good role design**:
- Small, focused roles
- Clear variable interfaces
- Documented dependencies
- Reusable across projects
- Easy to test independently

**Signs you need to refactor**:
- Copy-pasting tasks between roles
- Similar patterns in multiple roles
- Hard to maintain/update common logic
- Roles doing too much

**Result**:
- More maintainable playbooks
- Faster role development
- Consistent behavior
- Easier testing and debugging
