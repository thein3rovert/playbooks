# Ansible Playbooks

Ansible playbooks and roles for managing development and production infrastructure.

## Quick Start

This project includes a `justfile` for simplified command execution. You can use either `just` commands or run `ansible-playbook` directly.

**Note:** Authentication is configured to be passwordless:
- Vault password is stored in `.vault_pass` (gitignored)
- Become password is stored in the encrypted vault file
- No password prompts required for any commands

### Using Just (Recommended)

#### List available commands:
```bash
just
```

#### Run all roles on production:
```bash
just all
```

#### Run all roles on dev:
```bash
just all-dev
```

#### Run specific role on production:
```bash
just run backup
```

#### Run specific role on dev:
```bash
just run-dev backup
```

#### Run on specific host (production):
```bash
just host bellamy
```

#### Run on specific host (specify environment):
```bash
just host ubuntu-srv-01 dev
```

#### Run specific role on specific host:
```bash
just run-host backup bellamy              # Production (default)
just run-host backup nixos-runner dev     # Dev environment
```

#### Dry run commands:
```bash
just dry-run-host ping bellamy            # Production (default)
just dry-run-host ping nixos-runner dev   # Dev environment
just dry-all                              # Dry run all on production
just dry-all-dev                          # Dry run all on dev
```

### Using Ansible Directly

#### Run all roles on production:
```bash
ansible-playbook -i inventory/production.yml site.yml
```

#### Run all roles on dev:
```bash
ansible-playbook -i inventory/dev.yml site.yml
```

#### Run specific role with tags:
```bash
ansible-playbook -i inventory/production.yml site.yml --tags backup
```

#### Run on specific host:
```bash
ansible-playbook -i inventory/production.yml site.yml --limit bellamy
```

#### Run specific role on specific host:
```bash
ansible-playbook -i inventory/production.yml site.yml --limit bellamy --tags backup
```

## Directory Structure

```
.
├── ansible.cfg              # Ansible configuration
├── site.yml                 # Main playbook
├── inventory/               # Inventory files and variables
│   ├── production.yml       # Production hosts
│   ├── dev.yml              # Development hosts
│   ├── localhost.yml        # Local execution
│   ├── group_vars/          # Group-level variables
│   └── host_vars/           # Host-specific variables
├── roles/                   # Ansible roles
│   ├── backup/              # Backup configuration
│   ├── nix/                 # Nix package manager setup
│   ├── systemd/             # Systemd service management
│   ├── tailscale/           # Tailscale VPN setup
│   └── user/                # User management
└── vars/                    # Additional variables
    ├── vault.yml            # Encrypted secrets
    └── tailscale.yml        # Tailscale configuration
```

## Inventory

See [inventory/README.md](inventory/README.md) for detailed inventory documentation.

### Environments

- **Production**: bellamy, finn, trikru
- **Development**: ubuntu-srv-01

## Available Roles

### Backup
Configures backup tasks for servers.
```bash
ansible-playbook -i inventory/production.yml site.yml --tags backup
```

### Nix
Installs and configures Nix package manager.
```bash
ansible-playbook -i inventory/production.yml site.yml --tags nix
```

### Systemd
Manages systemd services and configurations.
```bash
ansible-playbook -i inventory/production.yml site.yml --tags systemd
```

### Tailscale
Sets up Tailscale VPN connections.
```bash
ansible-playbook -i inventory/production.yml site.yml --tags tailscale
```

### User
Manages user accounts and permissions.
```bash
ansible-playbook -i inventory/production.yml site.yml --tags user
```

## Common Operations

### Using Just

#### List available roles:
```bash
just list
```

#### List hosts in inventory:
```bash
just list-hosts           # Production (default)
just list-hosts dev       # Development
```

#### Check what would change (dry run):
```bash
just check                # Production
just check dev            # Development
```

#### Syntax check:
```bash
just syntax
```

#### Manage vault:
```bash
just vault                # Edit vault file
just rekey-vault          # Change vault password
```

### Using Ansible Directly

#### Check what would change (dry run):
```bash
ansible-playbook -i inventory/production.yml site.yml --check
```

#### Run with verbose output:
```bash
ansible-playbook -i inventory/production.yml site.yml -v
```

#### Run with become password prompt:
```bash
ansible-playbook -i inventory/production.yml site.yml --ask-become-pass
```

#### Run with vault password prompt:
```bash
ansible-playbook -i inventory/production.yml site.yml --ask-vault-pass
```

#### List all hosts in inventory:
```bash
ansible-inventory -i inventory/production.yml --list
```

#### List all tags:
```bash
ansible-playbook -i inventory/production.yml site.yml --list-tags
```

#### List all tasks:
```bash
ansible-playbook -i inventory/production.yml site.yml --list-tasks
```

## Configuration

The `ansible.cfg` file contains default settings. Key configurations:

- **Inventory**: Specify with `-i` flag (production.yml or dev.yml)
- **Vault password file**: `.vault_pass` (automatically loaded, no prompts)
- **Forks**: 5 parallel processes
- **Python interpreter**: /usr/bin/python3
- **Host key checking**: Disabled

### Setting Up Authentication

1. **Create vault password file:**
   ```bash
   echo "your_vault_password" > .vault_pass
   chmod 600 .vault_pass
   ```

2. **Add become password to vault:**
   ```bash
   just edit
   # Add line: ansible_become_password: your_sudo_password
   ```

Once configured, all commands run without password prompts.

## Vault Management

Encrypted variables are stored in `vars/vault.yml`.

### Edit vault:
```bash
ansible-vault edit vars/vault.yml
```

### Encrypt new file:
```bash
ansible-vault encrypt vars/newfile.yml
```

### Decrypt file:
```bash
ansible-vault decrypt vars/vault.yml
```

## Development

### Testing changes locally:
```bash
ansible-playbook -i inventory/localhost.yml site.yml --tags <role>
```

### Testing on dev environment:
```bash
ansible-playbook -i inventory/dev.yml site.yml --check
```

## Requirements

- Ansible 2.9+
- Python 3.x
- SSH access to target hosts
- [just](https://github.com/casey/just) command runner (optional, but recommended)

## Support

For issues or questions, refer to the Ansible documentation at https://docs.ansible.com
