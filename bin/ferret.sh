#!/bin/bash

function run() {
  echo -e "$1"

  # write temp --init-file script from stdin
  bash -s 2>&1 | sed "s/^/  /"
  echo
}