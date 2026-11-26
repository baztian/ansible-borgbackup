# borgbackup / borgmatic ansible role

![CI](https://github.com/baztian/ansible-borgbackup/workflows/CI/badge.svg)

Ansible role to install [BorgBackup](https://www.borgbackup.org/) along with
[borgmatic](https://torsion.org/borgmatic/) to allow for automated backup.

The configuration parts are based on
[jprltsnz.borgmatic](https://galaxy.ansible.com/jprltsnz/borgmatic) and
[m3nu.ansible_role_borgbackup](https://galaxy.ansible.com/m3nu/ansible_role_borgbackup).

## Requirements

The `respositories` parent directory from `borgmatic_configs` (see below) need to exist, or this role
will fail.

## Role variables

* `borgmatic_init_repos`: Whether to initialize the repos or not. Set to `False` if
  you want to initialize with `borgmatic init...` yourself.
* `borgmatic_init_encryption`: The
  [encryption algorithm](https://torsion.org/borgmatic/docs/how-to/set-up-backups/#initialization) to use.
  By default it is set to `none`. This selects the encryption mode; it is not the repository passphrase.
* `borgmatic_timer`: The `borgmatic.timer`'s `OnCalendar` value. See
  [systemd documentation](https://www.freedesktop.org/software/systemd/man/systemd.time.html#Calendar%20Events)
  for valid values.
* `borgmatic_configs`: A dict with the contents of borgmatic per application configuration file. This is copied
  verbatim to the borgmatic config folder. This role is set for
  [per-application setup](https://torsion.org/borgmatic/docs/how-to/make-per-application-backups/). See the
  [borgmatic reference documentation](https://torsion.org/borgmatic/docs/reference/configuration/) for a
  complete list of available configuration.
* `borgmatic_kuma`: Optional Uptime Kuma settings. When at least one repository token is non-empty, the role
  installs a protected environment file and adds success and error hooks to each borgmatic configuration.
  Kuma hooks require borgmatic 1.8 or 1.9; borgmatic 2 changes after-backup hook behavior and is not supported.
  Repository keys must use uppercase letters, digits, and underscores. Matchers support Bash glob patterns.
  Store tokens with Ansible Vault.

Example:

```yaml
borgmatic_kuma:
  url: "http://192.168.178.224:3001"
  repositories:
    HOME_LOCAL:
      matcher: "/srv/backups/home.borg"
      token: "{{ kuma_token_home_local }}"
    HOME_NAS:
      matcher: "ssh://mybackup@nas*home.borg"
      token: "{{ kuma_token_home_nas }}"
```

The role writes `/etc/borgmatic.d/kuma.env` with mode `0600` and installs
`/usr/local/sbin/borgmatic-kuma-push` with mode `0750`. Empty or omitted tokens disable their matchers.
Successful `create` actions notify Kuma, whether scheduled or manual; initialization and listing do not. The
`on_error` hook also reports prune, compact, and check failures, including failures after a successful backup.

## Protecting secrets with Ansible Vault

Keep Borg repository passphrases and Kuma tokens in an Ansible Vault-encrypted variables file. Reference
the passphrase from `borgmatic_configs`:

```yaml
borgmatic_configs:
  backup-home:
    encryption_passphrase: "{{ vault_borgmatic_passphrase }}"
```

For example, define `vault_borgmatic_passphrase`, `kuma_token_home_local`, and `kuma_token_home_nas` in
`group_vars/servers/vault.yml`, then encrypt that file:

```sh
ansible-vault encrypt group_vars/servers/vault.yml
ansible-playbook --ask-vault-pass site.yml
```

The role writes borgmatic configuration files with mode `0600`. Vault protects secrets at rest in your
Ansible repository; root on a managed host can still read the generated configuration and Kuma environment file.

## User backups alongside system backups

The separate `baztian.borgbackup_user` role manages user-level backups. It does not disable this role's system
timer. Install that role separately if wanted.

## Running Molecule tests

Run these commands from the role repository root. Docker must be available.

```sh
molecule test
molecule test -s kuma
```

The default scenario covers system-wide mode. The `kuma` scenario tests permissions and notifications on both
supported distributions.

## Example Playbook

    - hosts: servers
      become: yes
      roles:
         - role: baztian.borgbackup
      vars:
        borgmatic_configs:
          backup-etc:
            source_directories:
                - /etc
            repositories:
                - path: /srv/backup_etc
                  label: local
            atime: false
            exclude_patterns:
              - icon_cache
            keep_daily: 7
            keep_weekly: 4
            keep_monthly: 12

          backup-home:
            source_directories:
              - /home
            repositories:
              - path: /srv/backup_home
                label: local
            atime: false
            exclude_patterns:
              - icon_cache
            keep_daily: 7
            keep_weekly: 4
            keep_monthly: 12

## License

MIT
