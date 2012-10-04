#!/bin/bash

# tests run in a tmp directory, hard code /app in environment for `heroku` to work
export GEM_PATH=/app/vendor/bundle/ruby/1.9.1
export PATH=/app/bin:/app/vendor/bundle/ruby/1.9.1/bin:/usr/local/bin:/usr/bin:/bin

echo "setting up ~/.ssh"

mkdir -p $HOME/.ssh

cat >$HOME/.ssh/config <<EOF
StrictHostKeyChecking no
EOF

[ -n "$SSH_PRIVATE_KEY" ] && echo "$SSH_PRIVATE_KEY" >$HOME/.ssh/id_rsa
[ -n "$SSH_PUBLIC_KEY" ]  && echo "$SSH_PUBLIC_KEY"  >$HOME/.ssh/id_rsa.pub
