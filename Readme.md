# Ferret

Ferret is a framework to set up canary apps and test processes:

```
Heroku Org          ferret
  Control App         ferretapp
    Test Process        test/git_clone
    Test Process        test/convergence
  Target App          ferret-git-clone
  Target App          ferret-convergence
```

The Control App test process logs are drained to l2met, where service availability and service time can be calculated and visualized via Librato 
Metrics.

## Control App Setup

```sh
# NOTE: You can bypass this by joining $ORG.

# Create an unpriveledged GMail account, sign up for Heroku, and save the keys
$ export                                                                  \
    UNPRIVILEGED_HEROKU_API_KEY=deadbeef87a9b10d49ab5036216c41b7f8cc3633  \
    UNPRIVILEGED_GMAIL_USER=heroku.ferret@gmail.com:deadbeef84c277fa

# Create an app and add the API keys
$ export APP=ferretapp
$ heroku create $APP
$ heroku config:set                                                       \
    APP=$APP                                                              \
    GMAIL_USER=$UNPRIVILEGED_GMAIL_USER                                   \
    HEROKU_API_KEY=$UNPRIVILEGED_HEROKU_API_KEY

# Add the account and transfer the app to the "ferret" Heroku Manager org
$ export ORG=ferret
$ heroku manager:add_user                                                 \
    --org $ORG --user ${UNPRIVILEGED_GMAIL_USER%:*} --role admin
$ heroku manager:transfer --to $ORG

# Build and release the code, then run the tests
$ heroku build -b https://github.com/nzoschke/buildpack-ferret.git -r $APP
$ heroku run "test/ferret; test/ferret_online"

# Send metrics to Librato via https://www.l2met.net/

$ heroku sudo passes:add logplex-beta-program
$ heroku drains:add https://drain.l2met.net/consumers/36f8e609-df04-4da2-8630-86a959f41c68/logs
```

## Local Run

```sh
$ test/git_clone
app=ferret.git_clone xid=40ff7bbd fn=heroku_info_create i=0 at=enter
app=ferret.git_clone xid=40ff7bbd fn=heroku_info_create i=0 status=0 measure=heroku_info_create.success
app=ferret.git_clone xid=40ff7bbd fn=heroku_info_create i=0 at=return val=6.515912 unit=s measure=heroku_info_create.time
app=ferret.git_clone xid=40ff7bbd fn=clone i=0 at=enter
app=ferret.git_clone xid=40ff7bbd fn=clone i=0 status=0 measure=clone.success
app=ferret.git_clone xid=40ff7bbd fn=clone i=0 at=return val=12.826495 unit=s measure=clone.time
app=ferret.git_clone xid=40ff7bbd fn=exit
```

## Platform Run

```sh
$ heroku run git_clone

# OR

$ heroku scale git_clone=1
```

## Philosophy

Ferret is a simple framework for applying the canary pattern for Heroku kernel services. Much thought is given on how to measure properties of services in isolation.

Ferret *does not* implement complex platform integration tests, though these 
would be easy to build with the framework.

## Test App Development

Simple test processes follow a pattern. See `test/exec_run` as an example.

First, test if the $TARGET_APP already exists, and if not create it and
transfer it to the $ORG (:setup, using `heroku info || heroku create`).

Next perform some tests on the $TARGET_APP (:run, using `heroku run true`).

The `bash` helper will automatically log a counter for success or failure, as
well as a value for the time if successful, or logs if a failure. Environment
variables for $ORG, $TARGET_APP, etc. are pre-set for convenience.

Tests are not limited to `bash` however. See `test/librato` for "tests"
performed in Ruby, logging custom measurements.

## Platform Features

Ferret uses many of the latest features of Heroku to make the tools secure,
discoverable, configuration free, and maintenance free:

* S3
* Anvil
* Custom Buildpack (https://github.com/nzoschke/buildpack-ferret)
* Heroku Toolbelt
* Dot Profile (dot-profile-d feature)
* Heroku Manager
* HTTP Log Drains
* L2Met
* Librato

## Todo

* HTTP canaries
* Build canaries
* Tooling around Heroku setup/teardown
* Tooling around Librato configuration
* Warning / Alerting
