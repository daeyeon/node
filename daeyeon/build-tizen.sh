#!/bin/bash

set -e

START_TIME=$SECONDS

# GBS_PROFILE="profile.t65std"
GBS_PROFILE="t65std"
GBS_ARCH="armv7l"

# GBS_PROFILE="tizen_unified_standard"
# GBS_ARCH="armv7hl"

GBS_BUILD_ROOT_NAME="node-18"
GBS_CONF_FPATH="./packaging/gbs.conf"
GBS_EXTRA_ARGS=

gbs() {
  local buildroot_name=$1
  local gbs_conf_fpath=$2
  local gbs_arch=$3
  local gbs_profile=$4
  local more_option=$5

  local gbs_command="gbs -c $gbs_conf_fpath "
  gbs_command+="build -B ~/GBS-ROOT/$buildroot_name "
  gbs_command+="-A $gbs_arch --include-all --incremental -P $gbs_profile "
  gbs_command+=$more_option

  echo $gbs_command
  bash -c "${gbs_command}"
  echo $gbs_command
}

post() {
  # local RPM_OUTPUT=~/GBS-ROOT/$GBS_BUILD_ROOT_NAME/local/repos/t65std/armv7l/RPMS
  local RPM_OUTPUT=~/GBS-ROOT/$GBS_BUILD_ROOT_NAME/local/repos/$GBS_PROFILE/$GBS_ARCH/RPMS

  rm -rf rpm;
  mkdir -p rpm;

  echo -e "\nbundle devels\n"

  cd rpm
  find $RPM_OUTPUT -name '*.rpm' | grep -e '/[a-z]*-[0-9]\|-devel' | xargs -I {} sh -c "rpm2cpio {} | cpio -idm"
  find usr/bin usr/lib -name "node*" -o -name "*.so*" | xargs tar --transform 's/.*\///g' -cf node.tar
  tar -xf node.tar
  cd - > /dev/null

  rm -rf rpm/usr rpm/node.tar
  # bash -c "./build-post.sh rpm"
}


# [[ $1 =~ .*"d" ]] && GBS_EXTRA_ARGS="$GBS_EXTRA_ARGS --define 'debug_symbols 1'"
# [[ $1 =~ .*"e" ]] && GBS_EXTRA_ARGS="$GBS_EXTRA_ARGS --define 'static_escargot 1'"
# [[ $1 =~ .*"f" ]] && GBS_EXTRA_ARGS="$GBS_EXTRA_ARGS --define 'feature_mode development'"
# ! [[ $1 =~ .*"s" ]] && GBS_EXTRA_ARGS="$GBS_EXTRA_ARGS --define 'lib_type static'"

echo -e "\n# $GBS_EXTRA_ARGS\n"

gbs $GBS_BUILD_ROOT_NAME \
    $GBS_CONF_FPATH \
    $GBS_ARCH \
    profile.$GBS_PROFILE \
    "$GBS_EXTRA_ARGS"

if [ $? -eq 0 ]; then
  post
fi

ELAPSED_TIME=$(($SECONDS - $START_TIME))
ELAPSED_TIME_STR="$(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec"
echo -e "\nDone ($@) $ELAPSED_TIME_STR"

# ./build-tizen.sh --clean
# ./build-tizen.sh --define \'external_script_config --enable-external-builtin-script\'


# gbs -c .circleci/gbs.conf build -A armv7l -P profile.t65std --include-all --incremental
# local/BUILD-ROOTS/scratch.armv7l.0/home/abuild/rpmbuild/RPMS/armv7l

# PSS+SWAP: 9,956 kB
# PSS+SWAP: 9,918 kB
# PSS+SWAP: 8,706 kB

# cd ~/artifacts
# find . -name '*.rpm' | grep -e '/[a-z]*-[0-9]\|-devel' | xargs -I {} sh -c "rpm2cpio {} | cpio -idmv"
# find usr/bin usr/lib -name "lwnode*" -o -name "*.so*" | xargs tar --transform 's/.*\///g' -cvf lwnode.tar
# rm -rf usr
