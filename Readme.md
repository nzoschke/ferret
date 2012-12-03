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

## Development Control App Setup

Get a HEROKU_API_KEY for an unpriveledged $GMAIL_USER, and an [L2Met drain](https://www.l2met.net/) for a personal Librato account.

Copy `env.sample` to `.env`, and fill in APP, HEROKU_API_KEY and L2MET_URL, then run the setup script via Foreman.

```sh
cp env.sample .env
foreman run bin/setup.sh
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
* OAuth canary
* Tooling around Heroku setup/teardown
* Tooling around Librato configuration
* Warning / Alerting
* Measure l2met / librato delay
