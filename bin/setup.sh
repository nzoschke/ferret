#!/bin/bash

[ "$UNPRIVILEGED_HEROKU_API_KEY" ] || { echo UNPRIVILEGED_HEROKU_API_KEY required; exit 1; }

# client and account pre-reqs
heroku plugins:install https://github.com/heroku/manager-cli.git
heroku plugins:install https://github.com/ddollar/heroku-anvil.git
heroku sudo passes:add logplex-beta-program

heroku apps:create $APP
heroku config:set --app ${APP}                        \
  APP=$APP                                            \
  HEROKU_API_KEY=$UNPRIVILEGED_HEROKU_API_KEY

heroku manager:add_user													      \
  --org $ORG --user ${GMAIL_USER} --role admin --app ${APP}
heroku manager:transfer --to $ORG --app ${APP}

heroku build -b https://github.com/nzoschke/buildpack-ferret.git -r $APP
heroku run "test/ferret; test/ferret_online" --app ${APP}

heroku drains:add --app ${APP} ${L2MET_URL}
