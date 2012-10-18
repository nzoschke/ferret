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
$ test/git_push
app=ferret-git-push xid=e5481d29 fn=heroku-info-create i=0 at=enter 
app=ferret-git-push xid=e5481d29 fn=heroku-info-create i=0 at=heroku-info-create-success status=0 measure=true 
app=ferret-git-push xid=e5481d29 fn=heroku-info-create i=0 at=return elapsed=2.488483 measure=true 
app=ferret-git-push xid=e5481d29 fn=init-commit i=0 at=enter 
app=ferret-git-push xid=e5481d29 fn=init-commit i=0 at=init-commit-success status=0 measure=true 
app=ferret-git-push xid=e5481d29 fn=init-commit i=0 at=return elapsed=0.016346 measure=true 
app=ferret-git-push xid=e5481d29 fn=push i=0 at=enter 
app=ferret-git-push xid=e5481d29 fn=push i=0 at=push-success status=0 measure=true 
app=ferret-git-push xid=e5481d29 fn=push i=0 at=return elapsed=32.92235 measure=true 
app=ferret-git-push xid=e5481d29 fn=exit 
```

## Platform Run

```sh
$ heroku run git_push

# OR

$ heroku scale git_push=1
```

## Metrics

Create an account on Librato use it to get a drain on https://www.l2met.net/

```sh
$ heroku sudo passes:add logplex-beta-program
$ heroku drains:add https://drain.l2met.net/consumers/36f8e609-df04-4da2-8630-86a959f41c68/logs
```
