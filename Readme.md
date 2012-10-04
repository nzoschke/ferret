# Ferret

## Setup

Create a disposable GMail account and sign him up for Heroku. Create an app, 
collaborate him, and add his Heroku and GMail keys. Push the code, then run the
setup script on the platform, to generate and save ssh keys.

```sh
$ export                                                            \
  APP=ferretapp                                                     \
  UNPRIVILEGED_API_KEY=deadbeef87a9b10d49ab5036216c41b7f8cc3633     \
  UNPRIVILEGED_GMAIL_USER=heroku.ferret@gmail.com:deadbeef84c277fa

$ heroku create $APP
$ heroku sharing:add ${UNPRIVILEGED_GMAIL_USER%:*}
$ heroku config:set                                                 \
  APP=$APP                                                          \
  GMAIL_USER=$UNPRIVILEGED_GMAIL_USER                               \
  HEROKU_API_KEY=$UNPRIVILEGED_API_KEY

$ git push heroku master

$ heroku run bin/setup.sh
```

## Run

```sh
$ heroku run ferret/git-push-cedar
```

## Scale

```sh
$ heroku scale git_push_cedar=1
```