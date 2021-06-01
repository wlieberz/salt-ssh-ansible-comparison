#!/usr/bin/env  bash

if [ -z $1 ]; then
   echo $0 user@host.com
   exit 0
fi

ssh-copy-id -i etc/salt/pki/master/ssh/salt-ssh.rsa.pub $1
