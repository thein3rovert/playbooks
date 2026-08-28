# User Role

Creates a non-root account with a public key and then hardens SSH access.

## Required variables

- `default_user`: non-root login account
- `default_group`: primary account group
- `ssh_pub_key`: public key authorized for the account

## Safety behavior

The role stops before changing SSH settings when the account, public key,
`authorized_keys` file, or SSH daemon validator is unavailable. The candidate
configuration must pass `sshd -t` before replacing the active configuration.
After a safe reload, the role resets Ansible's connection and verifies a new
key-based connection as `default_user`.

Override `user_sshd_binary` or `user_ssh_service_name` for platforms whose SSH
binary or service name differs from the defaults.

Debian, Red Hat, and SUSE families are supported by default. NixOS and other
declarative systems are skipped because their users and SSH settings should be
managed through the operating-system configuration rather than editing
`/etc/ssh/sshd_config` imperatively.
