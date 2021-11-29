#!/bin/bash

print_red() {
  tput setaf 1
  echo "$1"
  tput setaf 7
}

release_submodule() {

  VERSION_OLD="$1"
  VERSION_NEW="$2"
  SUBMODULE="$3"

  printf '\n\nReleasing %s\n\n\n' "$SUBMODULE"

  if [[ $(git status --porcelain) ]]; then
    print_red "Git changes detected, either add and commit these or remove them before installing. Skipping"
    return
  fi

  GIT_STATUS_POR_BRA=$(git status --porcelain --branch)

  if [[ "$GIT_STATUS_POR_BRA" == *"ahead"* ]]; then
    print_red "Local commits are ahead of upstream, push these before releasing. Skipping."
    return
  fi

  if [[ "$GIT_STATUS_POR_BRA" == *"behind"* ]]; then
    print_red "Local commits are behind upstream, pull and/or merge these before releasing. Skipping."
    return
  fi

  if ! [[ "$GIT_STATUS_POR_BRA" == *"## master"* ]]; then
    print_red "Currently not on master branch, move to master branch before releasing. Skipping."
    return
  fi

  TEST_LOG=$(curl -L "https://img.shields.io/github/workflow/status/ivy-dl/$SUBMODULE/nightly-tests")

  if [ -z "$TEST_LOG" ]; then
    print_red "The test log returned empty, so cannot determine if the tests are passing or failing. Skipping."
    return
  fi

  if [[ "$TEST_LOG" == *"failing"* ]]; then
    print_red "The tests for the latest commit are failing, fix these failing tests before releasing. Skipping."
    return
  fi

  if ! [[ "$TEST_LOG" == *"passing"* ]]; then
    print_red "The tests for the latest commit are not passing, fix these failing tests before releasing. Skipping."
    return
  fi

  if [ -z "$VERSION_OLD" ]; then
    print_red "You need to provide an old version number"
    return
  fi

  if [ -z "$VERSION_NEW" ]; then
    print_red "You need to provide a release version number"
    return
  fi

  if ! grep -Fq "$VERSION_OLD" setup.py; then
    print_red "The old version is not present in setup.py. Skipping"
    return
  fi

  if grep -Fq "$VERSION_NEW" setup.py; then
    print_red "The new version already exists in setup.py. Skipping"
    return
  fi

  # shellcheck disable=SC2005
  PACKAGE_NAME=$(echo "$(grep -F "name=" setup.py)" | cut -f2 -d"'")
  PIP_RET=$(python3 -m pip index versions "$PACKAGE_NAME")
  PIP_HAS_OLD=$(echo "$PIP_RET" | grep -F "$VERSION_OLD")

  if [ -z "$PIP_HAS_OLD" ]; then
    print_red "The old version not found in PyPI. Skipping"
    return
  fi

  PIP_HAS_NEW=$(echo "$PIP_RET" | grep -F "$VERSION_NEW")

  if [ -n "$PIP_HAS_NEW" ]; then
    print_red "The new version already in PyPI. Skipping"
    return
  fi

  sed -i "s/$1/$2/g" setup.py
  git add -A
  git commit -m "version $2"
  git push
  git tag -a "v$2" -m "version $2"
  git push origin "v$2"
}

VERSION_OLD="$1"
VERSION_NEW="$2"
THIRD="$3"

if [[ "$THIRD" == "all" ]]; then
  SUBMODULES="ivy mech vision robot gym memory builder models"
else
  SUBMODULES="${*:3}"
fi

for SUBMODULE in $SUBMODULES
do
  cd "$SUBMODULE" || continue
  release_submodule "$VERSION_OLD" "$VERSION_NEW" "$SUBMODULE"
  cd ..
done