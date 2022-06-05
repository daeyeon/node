#!/bin/bash

# set -e

ARGS=$@
OPTION=

[[ -z $1 ]] && ARGS=doc/api/**/*
# [[ -z $1 ]] && LINT_MD_TARGETS=$(git diff --name-only `git merge-base master HEAD` | grep '.md$')

# echo LINT_MD_TARGETS: $LINT_MD_TARGETS

node tools/lint-md/lint-md.mjs $ARGS

# if ! [[ -z $LINT_MD_TARGETS ]]; then
#   node tools/lint-md/lint-md.mjs $LINT_MD_TARGETS
# fi

echo "done ("$ARGS")"
