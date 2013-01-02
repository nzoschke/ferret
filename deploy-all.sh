#!/bin/bash
find $1 \( -type f -a ! -name "*.rb" \) | xargs -I {} ./deploy.sh {}