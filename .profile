#!/bin/bash

# no-op if ssh keys are not in the environment
[ -z "$SSH_PRIVATE_KEY" ] || [ -z "$SSH_PUBLIC_KEY" ] && exit 0

# otherwise, write to $HOME/.ssh
echo "setting up ~/.ssh"

mkdir -p $HOME/.ssh

cat >$HOME/.ssh/config <<EOF
StrictHostKeyChecking no
EOF

echo "$SSH_PRIVATE_KEY" >$HOME/.ssh/id_rsa
echo "$SSH_PUBLIC_KEY"  >$HOME/.ssh/id_rsa.pub
