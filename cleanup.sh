#!/bin/bash
heroku manager:apps --org $1 | xargs -I {} heroku apps:delete {} --confirm {}