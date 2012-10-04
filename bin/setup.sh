#!/bin/bash

[ -n "$APP" ]            || { echo "error: APP required"; exit 1; }
[ -n "$HEROKU_API_KEY" ] || { echo "error: HEROKU_API_KEY required"; exit 1; }
[ -f $HOME/.ssh/id_rsa ] && { echo "error: ssh private key already exists"; exit 1; }

mkdir -p $HOME/.ssh
ssh-keygen -f $HOME/.ssh/id_rsa -N "" -t rsa
heroku keys:add   --app $APP
heroku config:set --app $APP SSH_PRIVATE_KEY="$(< $HOME/.ssh/id_rsa)" SSH_PUBLIC_KEY="$(< $HOME/.ssh/id_rsa.pub)"

# verify setup
git clone git@heroku.com:$APP.git && echo "Setup complete" || echo "Setup FAILED"