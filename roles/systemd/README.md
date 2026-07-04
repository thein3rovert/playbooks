# Systemd Role

Generic, reusable systemd service management role. Can be used by other roles or playbooks to manage any systemd service.

## Features

- ✅ Start/stop/restart/reload any service
- ✅ Enable/disable services on boot
- ✅ Optional daemon-reload
- ✅ Wait for service ports to become available
- ✅ Idempotent operations
- ✅ Backwards compatible with legacy tailscale/traefik tags

## Usage

### From Another Role (include_role)

```yaml
- name: Restart Vault service
  ansible.builtin.include_role:
    name: systemd
  vars:
    systemd_service_name: vault
    systemd_service_state: restarted
    systemd_service_enabled: true
    systemd_wait_for_port: 8200
    systemd_wait_timeout: 30
```

### From a Playbook

```yaml
- name: Manage services
  hosts: all
  tasks:
    - name: Ensure nginx is running and enabled
      ansible.builtin.include_role:
        name: systemd
      vars:
        systemd_service_name: nginx
        systemd_service_state: started
        systemd_service_enabled: true
```

### Direct Role Call (Traditional)

```yaml
- name: Manage services
  hosts: all
  roles:
    - role: systemd
      vars:
        systemd_service_name: vault
        systemd_service_state: restarted
        systemd_service_enabled: true
```

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `systemd_service_name` | string | `""` | **Required**. Name of the systemd service |
| `systemd_service_state` | string | `started` | Desired state: `started`, `stopped`, `restarted`, `reloaded` |
| `systemd_service_enabled` | bool | `true` | Enable service on boot |
| `systemd_service_daemon_reload` | bool | `false` | Run daemon-reload before operation |
| `systemd_wait_for_port` | int | `null` | Optional port to wait for (e.g., 8200 for Vault) |
| `systemd_wait_timeout` | int | `30` | Timeout in seconds for port check |

## Examples

### Start and enable a service

```yaml
- ansible.builtin.include_role:
    name: systemd
  vars:
    systemd_service_name: docker
    systemd_service_state: started
    systemd_service_enabled: true
```

### Restart a service after config change

```yaml
- name: Update config
  ansible.builtin.template:
    src: app.conf.j2
    dest: /etc/app/app.conf

- name: Restart service
  ansible.builtin.include_role:
    name: systemd
  vars:
    systemd_service_name: myapp
    systemd_service_state: restarted
```

### Reload systemd unit and start service

```yaml
- ansible.builtin.include_role:
    name: systemd
  vars:
    systemd_service_name: my-custom-service
    systemd_service_daemon_reload: true
    systemd_service_state: started
    systemd_service_enabled: true
```

### Stop and disable a service

```yaml
- ansible.builtin.include_role:
    name: systemd
  vars:
    systemd_service_name: old-service
    systemd_service_state: stopped
    systemd_service_enabled: false
```

## Backwards Compatibility

Legacy tag-based calls still work for tailscale and traefik:

```bash
# Still works
ansible-playbook site.yml --tags tailscale-restart
ansible-playbook site.yml --tags traefik-start
```

## Design Philosophy

This role follows the **Single Responsibility Principle** - it does one thing (manage systemd services) and does it well. Other roles should use this role rather than duplicating systemd tasks.

### Benefits

- **DRY**: No duplication of systemd logic across roles
- **Consistency**: Same behavior across all services
- **Testability**: Test once, use everywhere
- **Maintainability**: Update systemd logic in one place
- **Flexibility**: Works with any systemd service

## Migration Guide

### Before (Duplicated Logic)

```yaml
# In vault role
- name: Restart Vault service
  ansible.builtin.systemd:
    name: vault
    state: restarted
  become: true

- name: Enable Vault service
  ansible.builtin.systemd:
    name: vault
    enabled: true
  become: true

- name: Wait for Vault
  ansible.builtin.wait_for:
    port: 8200
```

### After (Reusable)

```yaml
# In vault role
- name: Restart and enable Vault service
  ansible.builtin.include_role:
    name: systemd
  vars:
    systemd_service_name: vault
    systemd_service_state: restarted
    systemd_service_enabled: true
    systemd_wait_for_port: 8200
```

## Requirements

- Ansible 2.9+
- Systemd-based Linux distribution
- Become/sudo privileges
