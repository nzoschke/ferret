# Ferret




To deploy a test to the platform run
```sh
deploy.sh filename
```

To run a test locally run
```sh
foreman run filename
```


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
2012-12-05T01:08:52+00:00 app[http_recurl.1]: app=ferret-dev-fode xid=49eab42b source=http_recurl fn=consider_restart i=0 at=enter
2012-12-05T01:08:53+00:00 app[http_recurl.1]: app=ferret-dev-fode xid=49eab42b source=http_recurl fn=consider_restart i=0 status=0 measure=success
2012-12-05T01:08:53+00:00 app[http_recurl.1]: app=ferret-dev-fode xid=49eab42b source=http_recurl fn=consider_restart i=0 val=100 measure=uptime
2012-12-05T01:08:53+00:00 app[http_recurl.1]: app=ferret-dev-fode xid=49eab42b source=http_recurl fn=consider_restart i=0 at=return val=0.629225798 measure=time

```

## Platform Run

```sh
$ heroku run tests/git_clone

# OR

$ heroku scale git_clone=1
```

## Philosophy

Ferret is a simple framework for applying the canary pattern for Heroku kernel services. Much thought is given on how to measure properties of services in isolation.

Ferret *does not* implement complex platform integration tests, though these 
would be easy to build with the framework.


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
