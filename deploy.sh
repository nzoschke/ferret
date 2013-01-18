#!/bin/bash

L2MET_URL=https://drain.l2met.net/consumers/6f65d7cc-5443-4a99-9545-8bec7a301941/logs
TARGET_APP_PATH=$1
APP=$(whoami)
ORG=ferret-dev
SCALE=10
UNPRIVILEGED_USER=heroku.ferret.dev@gmail.com
TARGET_APP_NAME=$(echo $TARGET_APP_PATH | sed -e 's:\./::' -e 's:[/._]:-:g')
APP=$APP-$TARGET_APP_NAME
echo "Setting up ${TARGET_APP_NAME} from path ${TARGET_APP_PATH}"
echo "Cleaning Procfile"
#cleanup procfile so that we can make the target app the tester proc
rm Procfile
touch Procfile
echo "tester: ${TARGET_APP_PATH}" >> Procfile

echo "Getting unprivileged api key from ${UNPRIVILEGED_USER}"
#someday we get to use oauth tokens instead of this hack
UNPRIVILEGED_HEROKU_API_KEY=$(heroku sudo user:info -x \
    --user ${UNPRIVILEGED_USER}                        \
  | awk '/Api Key:/ {print $3;}'                       \
  | head -1)
echo "Cleaning up old deploy of $APP"

heroku apps:delete $APP --confirm $APP

heroku apps:create $APP 
heroku manager:transfer --to $ORG --app ${APP}
heroku sharing:add $UNPRIVILEGED_USER --app ${APP}
heroku config:set --app ${APP}                         \
  APP=$APP                                             \
  HEROKU_API_KEY=$UNPRIVILEGED_HEROKU_API_KEY          \
  APP_PREFIX=ferret-$(whoami)						   \
  ORG=$ORG                                             \
  FREQ=1                                               \
  SERVICE_APP_NAME=$APP-s
heroku build -b https://github.com/nzoschke/buildpack-ferret.git -r $APP
heroku scale tester=${SCALE} --app $APP
heroku drains:add --app $APP $L2MET_URL