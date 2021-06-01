
# Purpose:

This is a proof of concept demo repo to configure an Ubuntu workstation with a few common developer tools. Tested on Ubuntu 20.04.2 LTS (Focal Fossa).

I am more familar with using Ansible for this type of automation, so this PoC is also to explore differences between Ansible and salt-ssh as well as salt-ssh's feature completeness and ease of use compared to Ansible.

For the sake of direct comparison, I have written the same set of configuration tasks into salt-ssh and ansible, each under their respective top-level directories in this repo. 

The configuration tasks are very simple:

Ensure installed:

  - git
  - tmux
  - chromium-browser
  - slack

Slack is the only tricky one: the deb or rpm (as appropiate) is copied into /tmp and installed, if not already installed. Note: a far better engineering practice, in production, potentially across hundreds of hosts, would be to host the packages in an internal repo, and then add the appropiate repo to the managed hosts and install with the package manager. Even in this scenario, we would need the ability to distinguish which hosts get which repo based on upon their Linux distro family, so this is still a fair test.

# Pre-reqs:

You might:

1. Install salt-ssh and Ansible locally on your new developer workstation, clone this repo and run one or both config management tools against localhost.

or

2. Run Ansible/salt-ssh from another host against your new dev workstation. 

Either way, there are a few steps you'll need to do first to get up and running:

- Ensure the user you will be using on the managed-system has passwordless sudo configured, if you want to use ssh key based authentication. If you don't have passwordless sudo, you can tell Ansible that you'd like to be asked for your become password. I am not sure if salt-ssh has this option.

- Ensure your ssh public key is added to the managed host's authorized_keys file. With Ansible, you can authenticate with a password, if you pass the flag '--ask-pass'. I'm not sure if salt-ssh has this option.

- Checking binary packages into git is a bad idea, so rpm & deb packages are excluded in .gitignore. Therefore you will need to download the slack deb and/or rpm and place them in: `salt/files/deb` and `salt/files/rpm` for salt-ssh, and for Ansible in:  `ansible/roles/slack/files`.

- If you wish to install a newer version of Slack, be sure to update the variables in `pillar/slack.sls` and `ansible/group_vars/DevWorkstations.yml` accordingly.

# salt-ssh Basics:

Commands take the form of:

```

salt-ssh [target] [command] [arguments]

```

Verify connectivity:

```

salt-ssh '*' test.ping

```

This should return root:

```

salt-ssh '*' cmd.run 'whoami'

```

In Salt's parlance, the top file maps which hosts should get which states applied to them. Running all applicable states against a host (according to the top file), is called invoking the highstate on a minion. This can be achieved thusly:

```

salt-ssh '*devworkstation*' state.apply

```

Variables are stored in pillars, which are similarly mapped to minions with a pillar top file. In this repo, in the pillar dir we have two files: top.sls and slack.sls. The slack.sls file contains the actual variables and the top.sls file maps which minions get access to the variables via name globbing targeting.

# Running Ansible

To apply the same configuration, on the Ansible side:

1. cd into the ansible directory 

2. Run:

```
ansible-playbook site.yml 

```

# Comparisons with Ansible:

I am probably biased toward Ansible at this point since I have been working intensively with Ansible for over a year now. Because of this, my mind is already more wired for Ansible's way solving problems and organizing information.

## 1. Organization of tasks: Playbooks and Roles vs States:

Something I like about Salt is the encouragement to write smaller states and organize them within a directory. For example, I have seen the example of a directory structure like:

salt/mysql:
  server-installed.sls
  client-installed.sls
  client-absent.sls

Then, with specific targeting in the top file, certain minions can just get the client, or the server tasks applied, and certain minions which might have had the client at one point can be targeted to ensure the mysql client software is absent. 

In this case the top file might look a bit like:

```
base:
  '*dbsrv*':
    - mysql.server-installed

  '*apisrv*':
    - mysql.client-installed

  '*websrv*':
    - mysql.client-absent

```

## 2. Task output and skipping tasks:

Have a look at the salt state to install Slack. I wanted to see how Salt handles conditionals based upon the minion's distro. 

I have a single state file: `salt/slack/install.sls` which handles installing the rpm or deb package, as appropiate, given that a dev might have a Fedora workstation or an Ubuntu workstation.


Looking at the output from the Slack state:

```
          ID: Install deb slack package
    Function: pkg.installed
      Result: True
     Comment: onlyif condition is true
              unless condition is true
     Started: 15:14:35.959717
    Duration: 231.316 ms
     Changes:   
----------
          ID: Install rpm slack package
    Function: pkg.installed
      Result: True
     Comment: onlyif condition is false
              unless condition is false
     Started: 15:14:36.191197
    Duration: 8.549 ms
     Changes: 

```

The fact that the task "Install rpm slack package" was not executed on my Ubuntu host is not as clear as Ansible's output would be. Ansible would show this particular task as "skipped" vs Salt reports that the state returned true, without changes. 

It is only by reading the detailed output above, that it is apparent that the rpm task was not run since "only if condition is false" and "unless condition is false". 

To me, Ansible's conditionals can be written in a more flexible manner in that you can have something like 'when not condition' or 'when condition' rather than the more limited terms 'onlyif' and 'unless'.

Also in the Slack salt state, we see that the deb or rpm is sourced from the salt-master itself. Being able to reference a file stored on the saltmaster via 'salt://path/to/file' is rather neat. However, I tested the 'install deb slack package' sate without the 'unless' statement, and the task failed. In other words, I ran it commented like so:

```

Install deb slack package:
  pkg.installed:
    - sources:
      - slackDebPkg: salt://files/deb/{{ pillar['slackDeb'] }}
    - onlyif:
      - fun: match.grain
        tgt: 'os_family:Debian'
    #- unless:
      #- dpkg -l slack-desktop

```

and got:


```

          ID: Install deb slack package                                                                                             
    Function: pkg.installed                                                                                                         
      Result: False                                                                                                                 
     Comment: The following packages failed to install/update: slackDebPkg
     Started: 15:24:55.320038
    Duration: 5012.545 ms
     Changes:  


```

I feel that this was an unexpected result, since the `pkg.installed` module was otherwise imdempotent. Needing to include an 'unless' statement to guarantee idempotence seems like it should be unncessary in this instance, especially given that we are not shelling out to a raw command, but using a salt module. 

## 3. Missing features:

Disclaimer: It could well be that I didn't do enough experimentation and research, but these handy features I regularly use in Ansible appear to be missing in Salt:

- Blocks. 

Using the block module to group a set of tasks is very handy, especially being able to apply a conditional statement to the block as a whole, helps keep the code dry (don't repeat yourself).

https://docs.ansible.com/ansible/latest/user_guide/playbooks_blocks.html

If you look in `ansible/roles/slack/tasks/main.yml` you will see I have used two blocks.

- Secrets Vault

This isn't so much a missing feature, as one that seems more involved to implement. Using Ansible-Vault to encrypt arbitrary files is very simple and easy. 

While very possible to have encrypted pillars, it seems to have a higher barrier to entry, at least from what I could tell. See the documentation on the gpg renderer:

https://docs.saltproject.io/en/latest/ref/renderers/all/salt.renderers.gpg.html

and compare that to Ansible Vault's docs:

https://docs.ansible.com/ansible/latest/user_guide/vault.html

That being said, Salt can pull pillar data from external services, including vaulting services such as HashiCorp Vault, which is probably not trivial to configure, but could be a very compelling solution. Of course, Ansible Tower can be configured to pull secrets from external providers as well:

https://docs.ansible.com/ansible-tower/3.5.0/html/administration/credential_plugins.html


## 4. Final thoughts:

If your Salt automation is already built-out and working well for you, and you want to explore an agentless architecture on at least some of your hosts, salt-ssh is a logical choice. 

If you are already using Ansible and it is working well for you, there aren't any compelling reasons I can see to switch to salt-ssh. 

Both Ansible and salt-ssh have quirks and "gotchas", it will be up to you and your team, which one makes sense to invest the time and effort into going deep with and learning how to implement the most elegant solutions possible. 

From my perspective, the Ansible documentation is much easier to understand and the Ansible modules are easier to discover. There also seems to be a larger community around Ansible at the moment. If you are starting from scratch, I would reccomend Ansible. One word of warning: since Ansible is extremely flexible, take the time to work as a team to develop standards and strategies for keeping the repo consistent.

There is a scaling concern with Ansible, in which case Salt (not salt-ssh) might be a better fit due to its use of ZeroMQ and persistent agents. 

A possible counter-argument to the scaling issue would be to create images with Packer, using Ansible as the provisioner, and to deploy the updated images with a higher-level tool like Terraform, whenever changes are needed. In other words, re-deploy the fleet rather than make changes in-place, especially for large changes. This can be a very powerful pattern, especially when the new hosts are deployed using a blue/green deployment pattern via orchestration and load-balancers.