#!/bin/bash
export HOST=$(/sbin/ifconfig | sed -n 's/.*inet addr:\([0-9.]\+\)\s.*/\1/p' | head -1)
export GEM_HOME=/tmp/gems
export PATH=$GEM_HOME/bin/:${PATH}
export USER=$(whoami)
