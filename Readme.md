# Ferret

## Setup

```sh
# Create a disposable GMail account, sign him up for Heroku, and save the keys
$ export                                                                  \
    UNPRIVILEGED_HEROKU_API_KEY=deadbeef87a9b10d49ab5036216c41b7f8cc3633  \
    UNPRIVILEGED_GMAIL_USER=heroku.ferret@gmail.com:deadbeef84c277fa

# Add the Heroku account to the "ferret" Heroku Manager org
$ heroku manager:add_user                                                 \
    --org ferret --user ${UNPRIVILEGED_GMAIL_USER%:*} --role admin

# Create an app and add the API keys
$ export APP=ferretapp
$ heroku create $APP
$ heroku config:set                                                       \
    APP=$APP                                                              \
    GMAIL_USER=$UNPRIVILEGED_GMAIL_USER                                   \
    HEROKU_API_KEY=$UNPRIVILEGED_HEROKU_API_KEY

# Transfer the app to the "ferret" org
$ heroku manager:transfer --to ferret

# Push the code and run the setup script on the platform to generate and save SSH keys
$ git push heroku master
$ heroku run bin/setup
```

## Local Run

```sh
$ export $(cat .env)
$ heroku run ferret/git-push-cedar
```

## Platform Run

```sh
$ heroku scale git_push_cedar=1
```