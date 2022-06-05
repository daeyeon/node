#!/bin/bash

set -e

# if [[ $1 =~ ^-.*s ]]; then
  # STRIP=1; shift
# fi

function post() {
  ! [[ -z $2 ]] && echo && find $1 -name "lwnode" -o -name "*.so*" | grep -v "/obj" | xargs strip -v $2
  echo; find $1 -name "lwnode" -o -name "*.so*" | grep -v "/obj\|TOC\|/licenses" | xargs size -t
  echo; find $1 -name "lwnode" -o -name "*.so*" -o -name "*.dat" | grep -v "/obj\|TOC\|/licenses" | xargs du -s
}

post $@
