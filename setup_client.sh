# client and account pre-reqs
cp env.sample .env
heroku plugins:install https://github.com/heroku/manager-cli.git
heroku plugins:install https://github.com/ddollar/heroku-anvil.git
heroku sudo passes:add logplex-beta-program