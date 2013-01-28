#!/bin/bash
[ -n "$APP" ]            || { echo "error: APP required"; exit 1; }
[ -n "$HEROKU_API_KEY" ] || { echo "error: HEROKU_API_KEY required"; exit 1; }

echo "setting up ~/.ssh"
mkdir -p $HOME/.ssh

cat >$HOME/.ssh/config <<EOF
StrictHostKeyChecking no
EOF

[ -n "$SSH_PRIVATE_KEY" ] && echo "$SSH_PRIVATE_KEY" >$HOME/.ssh/id_rsa
[ -n "$SSH_PUBLIC_KEY" ]  && echo "$SSH_PUBLIC_KEY"  >$HOME/.ssh/id_rsa.pub

if [ ! -f $HOME/.ssh/id_rsa ]; then
  ssh-keygen -f $HOME/.ssh/id_rsa -N "" -t rsa
  heroku keys:add   --app $APP
  heroku config:set --app $APP SSH_PRIVATE_KEY="$(< $HOME/.ssh/id_rsa)" SSH_PUBLIC_KEY="$(< $HOME/.ssh/id_rsa.pub)"
fi
