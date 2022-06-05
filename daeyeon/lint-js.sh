#!/bin/bash

set -e

ARGS=$@
OPTION=
FROM=upstream/master

# nvm use v16.15.0
# NODE=$(command -v node) make lint-js

# [[ -z $1 ]] && ARGS=lib/**/*
# LINT_JS_TARGETS=.eslintrc.js benchmark doc lib test tools
[[ -z $1 ]] && LINT_JS_TARGETS=$(git --no-pager diff --name-only \
                                `git merge-base master HEAD` | grep -E '.js$|.mjs$')

echo LINT_JS_TARGETS: $LINT_JS_TARGETS

tools/node_modules/eslint/bin/eslint.js --cache \
 	--max-warnings=0 \
   --report-unused-disable-directives \
   $LINT_JS_TARGETS

# run-lint-js-fix = $(run-lint-js) --fix

echo "done ("$ARGS")"

# @todo
# - 변경분만 검사하게 변경
# --format 옵션지원 (lint-md.mjs --format $(LINT_MD_FILES))

# @backup
# NODE=$(command -v node) make lint-md
# [[ $1 =~ .*"c" ]] && cat ./config.gypi
# RUN_LINT_JS_FIX=$RUN_LINT_JS --fix
# git di-nameonly-forked-from master | grep ".js$"