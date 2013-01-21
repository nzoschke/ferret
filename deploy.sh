#!/bin/bash

ORG=ferret-dev
UNPRIVILEGED_USER=heroku.ferret.dev@gmail.com
APP=ferret-app

rm Procfile
touch Procfile
bin/create_proc.sh $1

UNPRIVILEGED_HEROKU_API_KEY=$(bin/unprivileged.sh)
heroku sharing:add $UNPRIVILEGED_USER 
bin/push_config.sh

heroku build -b https://github.com/nzoschke/buildpack-ferret.git -r $APP

bin/scale $APP 1

heroku drains:add --app $APP $L2MET_URL