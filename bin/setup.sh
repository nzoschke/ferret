#!/bin/bash

[ -n "$APP" ]            || { echo "error: APP required"; exit 1; }
[ -n "$HEROKU_API_KEY" ] || { echo "error: HEROKU_API_KEY required"; exit 1; }

[ -n "$SSH_PRIVATE_KEY" ] && [ -n "$SSH_PUBLIC_KEYS" ] && { echo "warning: SSH vars already set"; exit 0; }

mkdir -p $HOME/.ssh
ssh-keygen -f $HOME/.ssh/id_rsa -N "" -t rsa
heroku keys:add   --app $APP
heroku config:set --app $APP SSH_PRIVATE_KEY="$(< $HOME/.ssh/id_rsa)" SSH_PUBLIC_KEY="$(< $HOME/.ssh/id_rsa.pub)"
