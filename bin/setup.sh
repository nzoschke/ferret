export 																	 \
    FERRET_USER=fode													 \
	UNPRIVILEGED_HEROKU_API_KEY=6413536ddc3a5a10e8f573ff28273b2521f1ea85 \
	UNPRIVILEGED_GMAIL_USER=heroku.ferret.dev@gmail.com

export APP=ferret-dev-${FERRET_USER}
heroku apps:create $APP
heroku config:set  --app ${APP}                                           \
	APP=$APP                                                              \
    GMAIL_USER=$UNPRIVILEGED_GMAIL_USER                                   \
    HEROKU_API_KEY=$UNPRIVILEGED_HEROKU_API_KEY

export ORG=ferret-dev 
heroku plugins:install https://github.com/heroku/manager-cli.git
heroku plugins:install https://github.com/ddollar/heroku-anvil.git
heroku manager:add_user													\
	--org $ORG --user ${UNPRIVILEGED_GMAIL_USER} --role admin --app ${APP}
heroku manager:transfer --to $ORG --app ${APP}
heroku sudo passes:add logplex-beta-program

heroku build -b https://github.com/nzoschke/buildpack-ferret.git -r $APP
heroku run "test/ferret; test/ferret_online" --app ${APP}


