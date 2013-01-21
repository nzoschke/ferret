UNPRIVILEGED_USER=heroku.ferret.dev@gmail.com

heroku sudo user:info -x                               \
    --user ${UNPRIVILEGED_USER}                        \
  | awk '/Api Key:/ {print $3;}'                       \
  | head -1
