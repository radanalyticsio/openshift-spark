#!/bin/bash

set -xe

main() {
  if [[ "${TRAVIS_JOB_NAME}" != "Push container images" ]] || \
     [[ "${TRAVIS_BRANCH}" = "master" && "${TRAVIS_PULL_REQUEST}" = "false" ]] || \
     [[ "${TRAVIS_TAG}" =~ ^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$ ]]; then
    pwd
    bash --version
    sudo apt-get install --only-upgrade bash
    bash --version
    ./test/prepare.sh
  else
    echo "[Before install] Not doing the ''./test/prepare.sh', because the tag '${TRAVIS_TAG}' is not of form x.y.z-n or we are not building the master branch"
  fi
}

main
