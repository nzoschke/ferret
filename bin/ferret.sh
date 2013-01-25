#!/bin/bash

function run() {
  echo "$1"
  bash -s 2>&1 | sed "s/^/  /"
}