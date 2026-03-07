# Inventory Structure

This directory contains Ansible inventory configurations for different environments.

## Files

- **production.yml** - Production environment hosts
- **dev.yml** - Development environment hosts
- **localhost.yml** - Local execution configuration

## Directory Structure

```
inventory/
├── production.yml          # Production hosts
├── dev.yml                 # Development hosts
├── localhost.yml           # Local execution
├── group_vars/
│   ├── production/all.yml  # Production environment variables
│   └── dev/all.yml         # Development environment variables
└── host_vars/
    ├── bellamy.yml         # Host-specific variables for bellamy
    └── finn.yml            # Host-specific variables for finn
```

## Usage

### Running playbooks against production:
```bash
ansible-playbook -i inventory/production.yml site.yml
```

### Running playbooks against dev:
```bash
ansible-playbook -i inventory/dev.yml site.yml
```

### Running playbooks locally:
```bash
ansible-playbook -i inventory/localhost.yml site.yml
```

## Hosts

### Production
- **bellamy** (100.105.187.63)
- **finn** (100.81.26.84)
- **trikru** (hostname-based)

### Development
- **ubuntu-srv-01** (hostname-based)

## Variables

### Group Variables
Group-level variables are defined in `group_vars/<environment>/all.yml` and apply to all hosts in that environment.

### Host Variables
Host-specific variables are defined in `host_vars/<hostname>.yml` and override group variables for that particular host.
