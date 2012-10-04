#!/bin/bash

TIMEOUT=${TIMEOUT:-120}

function _init() {
  PID=$$
  START=$(now)
  TEMP_DIR=/tmp/ferret-$RANDOM
  WORK_DIR=$(pwd)

  SRC_PATH=$(basename $0)
  TARGET_APP=ferret-${SRC_PATH%.*}

  log _init dir=\"$TEMP_DIR\" at=start

  mkdir -p $TEMP_DIR
  cd $TEMP_DIR

  exec 2>>$TEMP_DIR/log
  trap _exit EXIT

  trap _alarm SIGALRM
  (sleep $TIMEOUT; kill -ALRM $PID) &
  ALARMPID=$!
}

function _alarm() {
  log _alarm timeout=$TIMEOUT
  exit -1
}

function _exit() {
  STATUS=$?

  kill $ALARMPID
  rm -rf $TEMP_DIR
  cd $WORK_DIR

  ELAPSED=$(now $START)
  log _init dir=\"$TEMP_DIR\" at=exit elapsed=$ELAPSED status=$STATUS
}

function log() {
  echo app=ferret target_app=$TARGET_APP fn="$@"
}

function log_file() {
  sed "s/.*/app=ferret target_app=$TARGET_APP fn="$1" message=\"&\"/" < $2
}

function mail() {
  # check for GMAIL_USER var without leaking value into logs
  export | grep GMAIL_USER 1>/dev/null || { log mail at=error message=\"GMAIL_USER unset\"; exit -1; }

  ((BUCKET=$(date +%s)/60/5*5*60))
  SUBJECT="$1 @$BUCKET"
  TO=$2
  FROM=${GMAIL_USER%%:*}

  cat >message.txt <<EOF
From: <$FROM>
To: <$TO>
Subject: ERROR: $SUBJECT
Date: Thu, 26 Oct 2006 13:10:50 +0200
EOF

  cat log >> message.txt

  log_file mail message.txt

  # local START=$(now)
  #
  # log mail from=\"$FROM\" to=\"$TO\" subject=\"$SUBJECT\" at=start
  # curl -vi -n --ssl-reqd --mail-from "<$FROM>" --mail-rcpt "<$TO>" --url smtps://smtp.gmail.com:465 -T message.txt -u $GMAIL_USER
  # local STATUS=$?
  #
  # local ELAPSED=$(now $START)
  # log mail from=\"$FROM\" to=\"$TO\" subject=\"$SUBJECT\" at=$1 status=$? measure=true elapsed=$ELAPSED 

  exit 1
}

function retry() {
  N=$1
  STEP=$2
  TO=$3
  shift 3

  [ -t 0 ] && SCRIPT="$@" || SCRIPT=$(cat)

  X=0
  for ((i=0; i<N; i++)); do
    local START=$(now)
    log $STEP i=$i at=start

    bash -sx <<< "$SCRIPT" >>$TEMP_DIR/log 2>&1
    local STATUS=$?

    local ELAPSED=$(now $START)
    log $STEP i=$i at=finish status=$STATUS measure=true elapsed=$ELAPSED

    [ $STATUS -eq 0 ] && break || ((X++))
  done

  [ $N -eq $X ] && mail "$STEP" "$TO"
  return 0
}

function now() {
  ruby -e 'printf "%.2f", Time.now.to_f - ARGV[0].to_f' ${1:-0}
}

_init