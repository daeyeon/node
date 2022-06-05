#!/bin/bash

set -e

ARGS=$@

[[ -z $1 ]] && ARGS=src/**/*

cspell lint --show-suggestions -u $ARGS

echo "done ("$ARGS")"
