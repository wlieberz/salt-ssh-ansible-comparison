Role Name
=========

Role installs Slack for rpm or deb based hosts, if not already installed. 

Installation is handled by copying the rpm or deb package into /tmp/ and installing from there.

Requirements
------------

The deb and rpm packages must be present within the role's `files` directory. Since gitignore is configured to ignore deb and rpm packages, you are responsible for ensuring you have a copy of the packages on your ansible control host.

Role Variables
--------------

There is a var each for the rpm and deb packages which points to the full name of the rpm or deb file you wish to install. The role's `defaults/main.yml` has:

```

slack_rpm: slack-4.16.0-0.1.fc21.x86_64.rpm

slack_deb: slack-desktop-4.16.0-amd64.deb


```

So, if you use this version, and this version is present with in the role's `files` dir, you won't need to define these variables anywhere else. However, you can override the variables if you like within host_vars, group_vars, or within the playbook itself. See the Ansible documentation on variable precedence for more details:

https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#understanding-variable-precedence



Dependencies
------------


Example Playbook
----------------

- hosts: DevWorkstations
  become: true
  roles:
    - slack


License
-------

BSD

Author Information
------------------

William Lieberz
