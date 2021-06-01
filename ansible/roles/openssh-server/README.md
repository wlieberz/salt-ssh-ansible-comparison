Role Name
=========

Installs openssh-server from package manager.

Requirements
------------


Role Variables
--------------


Dependencies
------------

Example Playbook
----------------

- hosts: DevWorkstations
  become: true
  roles:
    - openssh-server

License
-------

BSD

Author Information
------------------

William Lieberz
