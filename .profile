#!/bin/bash
set -x

# if ssh keys are in the environment, write to $HOME/.ssh

[ -z "$SSH_PRIVATE_KEY" ] || [ -z "$SSH_PUBLIC_KEY" ] && exit 0

mkdir -p $HOME/.ssh

cat >$HOME/.ssh/config <<EOF
StrictHostKeyChecking no
EOF

echo "$SSH_PRIVATE_KEY" >$HOME/.ssh/id_rsa
echo "$SSH_PUBLIC_KEY"  >$HOME/.ssh/id_rsa.pub
