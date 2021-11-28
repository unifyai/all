#!/bin/bash

release_submodule() {

  VERSION_OLD="$1"
  VERSION_NEW="$2"
  SUBMODULE="$3"

  printf '\nReleasing %s\n\n' "$SUBMODULE"

  if [ -z "$VERSION_OLD" ]; then
      echo "You need to provide an old version number"
      exit
  fi
  if [ -z "$VERSION_NEW" ]; then
      echo "You need to provide a release version number"
      exit
  fi

  if ! grep -Fq "$VERSION_OLD" setup.py; then
      echo "The old version is not present in setup.py, exiting"
      exit
  fi

  if grep -Fq "$VERSION_NEW" setup.py; then
      echo "The new version already exists in setup.py, exiting"
      exit
  fi

  # shellcheck disable=SC2005
  PACKAGE_NAME=$(echo "$(grep -F "name=" setup.py)" | cut -f2 -d"'")
  PIP_RET=$(python3 -m pip index versions "$PACKAGE_NAME")
  PIP_HAS_OLD=$(echo "$PIP_RET" | grep -F "$VERSION_OLD")

  if [ -z "$PIP_HAS_OLD" ]; then
      echo "The old version not found in PyPI, exiting"
      exit
  fi

  PIP_HAS_NEW=$(echo "$PIP_RET" | grep -F "$VERSION_NEW")

  if [ -n "$PIP_HAS_NEW" ]; then
      echo "The new version already in PyPI, exiting"
      exit
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
for SUBMODULE in "${@:3}"
do
  cd "$SUBMODULE" || exit
  release_submodule "$VERSION_OLD" "$VERSION_NEW" "$SUBMODULE"
  cd ..
done