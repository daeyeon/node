#!/bin/bash

set -e

ARGS=$@
FLAKY_TESTS=run

# https://www.npmjs.com/package/clang-format
# BIN=tools/clang-format/node_modules/.bin/clang-format

[[ -z $1 ]] && ARGS=src/**/*



tools/test.py -J -p color --logfile test.tap \
		--mode=release \
    test/parallel

    # --flaky-tests=$FLAKY_TESTS


		# $(TEST_CI_ARGS) $(CI_JS_SUITES) $(CI_NATIVE_SUITES) $(CI_DOC)
ps awwx | grep Release/node | grep -v grep | cat
@PS_OUT=`ps awwx | grep Release/node | grep -v grep | awk '{print $$1}'`; \
if [ "$${PS_OUT}" ]; then \
  echo $${PS_OUT} | xargs kill -9; exit 1; \
fi

echo "done ("$ARGS")"

# usr/local/bin/python3.10 tools/test.py  -p tap --logfile test.tap \
# 	--mode=release --flaky-tests=run \
# 	-p actions default pummel addons js-native-api node-api benchmark
