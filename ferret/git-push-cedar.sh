#!/bin/bash
source $(dirname $0)/ferret.sh

retry 5 heroku-info-create noah@heroku.com <<EOF
  echo $PATH
  heroku info --app $TARGET_APP || heroku create $TARGET_APP
EOF

retry 1 temp-repo-create noah@heroku.com <<EOF
  git init app
  cd app
  git commit --allow-empty -m "empty"
EOF

retry 2 git-push-cedar noah@heroku.com <<EOF
  cd app
  git push -f git@heroku.com:$TARGET_APP.git master:test
EOF