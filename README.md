borgbackup ansible role
=======================

![CI](https://github.com/baztian/ansible-borgbackup/workflows/CI/badge.svg)

Ansible role to install [BorgBackup](https://www.borgbackup.org/) along with some scripts to allow for automated backup.

Example Playbook
----------------

    - hosts: servers
      become: yes
      roles:
         - role: baztian.borgbackup

License
-------

MIT
