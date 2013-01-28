# Ferret - Service Monitoring as a Service

Ferret is a framework to write **monitor processes** for network **services**.

Monitor processes output structured log data for all successes and failures
against the service, from which uptime is derived. Monitor processes both run
locally and are deployed to Heroku to run continuously.

Ferret also includes tools for managing services. These are generally disposable
canary Heroku apps.

## Development Setup

Edit env.sample and fill in HEROKU_USERNAME with your unpriveledged @gmail.com
Heroku account.

```bash
bin/setup

# Run all tests
foreman start

# Run tests with increased concurrency
foreman start --formation="monitors_git_clone=2"
```

## Platform Setup

```bash
# 
cp env.sample .env
foreman run bin/setup.sh

# Build and release the app
foreman run heroku build -b https://github.com/nzoschke/buildpack-ferret.git -r ferret-$FERRET_USER
```

## Philosophy

Ferret is designed to easily apply the canary pattern to Heroku kernel services.
Much thought should be given on how to measure properties of services in
isolation.

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
* `heroku ps` and `heroku scale`
* HTTP Log Drains
* L2Met
* Librato
