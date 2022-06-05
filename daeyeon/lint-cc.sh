#!/bin/bash

set -e

ARGS=$@

# https://www.npmjs.com/package/clang-format
# BIN=tools/clang-format/node_modules/.bin/clang-format

# [[ -z $1 ]] && ARGS=src/**/*
# CLANG_FORMAT_START ?= HEAD

# To format staged changes:
# make format-cpp

[[ -z $1 ]] && LINT_CC_TARGETS=$(git --no-pager diff --name-only \
                                `git merge-base master HEAD` | grep -E '.cc$|.h$')

git log -1 $(git merge-base master HEAD)
echo
echo LINT_CC_TARGETS: $LINT_CC_TARGETS
echo
CLANG_FORMAT_START=`git merge-base master HEAD` make format-cpp

# To format HEAD~1...HEAD (latest commit):
# CLANG_FORMAT_START=`git rev-parse HEAD~1` make format-cpp

# To format diff between master and current branch head (master...HEAD):
# CLANG_FORMAT_START=master make format-cpp


# make lint-cpp -s -j $(nproc) $@
# clang-format -i --style=file src/node_binding.cc
# clang-format -i --style=file $@

# 현재 change와 마지막 commit 비교하여 diff를 보여줌. -i 가 있으면 수정까지함.
# git diff -U0 --no-color HEAD | clang-format-diff -p1  # -i
# git --no-pager diff -U0 HEAD | clang-format-diff -p1

# 나의 마지막 커밋과 이전 커밋사이의 diff만 포맷함
# git diff -U0 --no-color HEAD^ | clang-format-diff -p1  # -i

# make format-cpp

# To format staged changes:
#  $ make format-cpp
# To format HEAD~1...HEAD (latest commit):
#  $ CLANG_FORMAT_START=`git rev-parse HEAD~1` make format-cpp
# To format diff between master and current branch head (master...HEAD):
#  $ CLANG_FORMAT_START=master make format-cpp
#
# make format-cpp
# format-cpp: ## Format C++ diff from $CLANG_FORMAT_START to current changes
# ifneq ("","$(wildcard tools/clang-format/node_modules/)")
# 	$(info Formatting C++ diff from $(CLANG_FORMAT_START)..)
# 	@$(PYTHON) tools/clang-format/node_modules/.bin/git-clang-format \
# 		--binary=tools/clang-format/node_modules/.bin/clang-format \
# 		--style=file \
# 		$(CLANG_FORMAT_START) -- \
# 		$(LINT_CPP_FILES)
# else
# 	$(info clang-format is not installed.)
# 	$(info To install (requires internet access) run: $$ make format-cpp-build)
# endif
#
# https://www.npmjs.com/package/clang-format
# https://github.com/nodejs/node/pull/42681/files
# CLANG_FORMAT_START=master make format-cpp

echo "done ("$ARGS")"

# Usage: make [options] [target] ...
# Options:
#   -b, -m                      Ignored for compatibility.
#   -B, --always-make           Unconditionally make all targets.
#   -C DIRECTORY, --directory=DIRECTORY
#                               Change to DIRECTORY before doing anything.
#   -d                          Print lots of debugging information.
#   --debug[=FLAGS]             Print various types of debugging information.
#   -e, --environment-overrides
#                               Environment variables override makefiles.
#   --eval=STRING               Evaluate STRING as a makefile statement.
#   -f FILE, --file=FILE, --makefile=FILE
#                               Read FILE as a makefile.
#   -h, --help                  Print this message and exit.
#   -i, --ignore-errors         Ignore errors from recipes.
#   -I DIRECTORY, --include-dir=DIRECTORY
#                               Search DIRECTORY for included makefiles.
#   -j [N], --jobs[=N]          Allow N jobs at once; infinite jobs with no arg.
#   -k, --keep-going            Keep going when some targets can't be made.
#   -l [N], --load-average[=N], --max-load[=N]
#                               Don't start multiple jobs unless load is below N.
#   -L, --check-symlink-times   Use the latest mtime between symlinks and target.
#   -n, --just-print, --dry-run, --recon
#                               Don't actually run any recipe; just print them.
#   -o FILE, --old-file=FILE, --assume-old=FILE
#                               Consider FILE to be very old and don't remake it.
#   -O[TYPE], --output-sync[=TYPE]
#                               Synchronize output of parallel jobs by TYPE.
#   -p, --print-data-base       Print make's internal database.
#   -q, --question              Run no recipe; exit status says if up to date.
#   -r, --no-builtin-rules      Disable the built-in implicit rules.
#   -R, --no-builtin-variables  Disable the built-in variable settings.
#   -s, --silent, --quiet       Don't echo recipes.
#   -S, --no-keep-going, --stop
#                               Turns off -k.
#   -t, --touch                 Touch targets instead of remaking them.
#   --trace                     Print tracing information.
#   -v, --version               Print the version number of make and exit.
#   -w, --print-directory       Print the current directory.
#   --no-print-directory        Turn off -w, even if it was turned on implicitly.
#   -W FILE, --what-if=FILE, --new-file=FILE, --assume-new=FILE
#                               Consider FILE to be infinitely new.
#   --warn-undefined-variables  Warn when an undefined variable is referenced.

# This program built for x86_64-pc-linux-gnu
