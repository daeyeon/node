#!/bin/bash

set -e

ARGS=$@
START_TIME=$SECONDS

function cleanup() {
  local ELAPSED_TIME=$(($SECONDS - $START_TIME))
  local ELAPSED_TIME_STR="$(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec"
  echo "done ($ARGS) $ELAPSED_TIME_STR"
}
trap cleanup SIGINT EXIT

CONFIG_V8="--without-npm \
  --without-intl \
  --shared-openssl --shared-zlib \
  --dest-os linux --dest-cpu x64"

CONFIG_FAST=" --without-node-snapshot \
              --without-inspector"

# ? --without-node-code-cache
# ? --enable-static
# ? --without-v8-platform
# CUSTOM=" --with-intl=system-icu"

CONFIG="$CONFIG_V8 $CONFIG_FAST $CUSTOM"

TARGET=node
# TARGET=embedtest

! [[ $1 =~ .*"n" ]] && CONFIG="$CONFIG --ninja"
[[ $1 =~ .*"s" ]] && CONFIG+=" --node-builtin-modules-path=$(pwd)"
[[ $1 =~ .*"f" ]] && cat ./config.gypi
[[ $1 =~ .*"v" ]] && NINJA_OPTION=-v
# clean build
[[ $1 =~ .*"0" ]] && CONFIG=""

PRINT_CONFIG_GYPI="bat --paging=never -r 2 -r 13:19 -r 309:323 -r 325:334 -r 346 ./config.gypi"

function copy-build() {
  local target_branch=${1:-master} # default: master
  local cur_branch=$(git br-name)
  local date=$(git log -1 --format=%cs)
  local postfix=$(git id).$date

  local out_path=${2:-out_} # default: out_
  local output=$out_path/node.$postfix

  if [[ $cur_branch == "$target_branch" ]]; then
    if [[ ! -f "$output" ]]; then
      mkdir -p $out_path
      cp -v ./out/Release/node $output
    fi
  fi
}

if [[ $1 =~ .*"d" ]]; then
  if [[ $1 =~ .*"c" ]]; then
    CONFIG="$CONFIG --debug --debug-node"
    echo configure: [$(echo $CONFIG | xargs)]
    sleep 1
    ./configure $CONFIG
  else
    $PRINT_CONFIG_GYPI
  fi

  if [[ $CONFIG =~ .*"ninja" ]]; then
    ninja $NINJA_OPTION -C out/Debug $TARGET |& ./build-colorize.sh
    # make node_g
  else
    make -j$(nproc)
  fi
else
  if [[ $1 =~ .*"c" ]]; then
    echo configure: [$(echo $CONFIG | xargs)]
    sleep 1
    ./configure $CONFIG
  else
    $PRINT_CONFIG_GYPI
  fi

  if [[ $CONFIG =~ .*"ninja" ]]; then
    ninja $NINJA_OPTION -C out/Release $TARGET |& ./build-colorize.sh
    # make node
  else
    make -j$(nproc)
  fi
  # copy master build only when clean-configure build
  # [[ -z $CONFIG || $CONFIG == " --ninja" ]] && copy-build master
fi






# ------------------------------------------------------------------------

# CONFIG_V8_LWNODE="--without-npm \
  # --without-inspector \
  # --without-node-snapshot \
  # --with-intl none --shared-openssl --shared-zlib \
  # --dest-os linux --dest-cpu x64"
  # --without-node-code-cache
  # --shared

# CONFIG_CI="--error-on-warn"
# --without-intl is same as --with-intl=none

# ------------------------------------------------------------------------

#   --error-on-warn       Turn compiler warnings into errors for node core
#                         sources.

# The motivation for this is that CI jobs can use this flag to turn
# warnings into errors.

# - name: Set up Ninja build
#   run: sudo apt install -y ninja-build
# - name: Build
#   run: |
#     ./configure --error-on-warn --ninja
#     ninja -v -C out/Release node
# - name: Test
#   run: make test-ci -j1 V=1 TEST_CI_ARGS="-p actions"
