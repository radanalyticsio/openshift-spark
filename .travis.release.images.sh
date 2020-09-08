#!/bin/bash
  
set -xe

OWNER="${OWNER:-radanalyticsio}"
IMAGES="${IMAGES:-
  openshift-spark
  openshift-spark-inc
}"

main() {
  if [[ "$TRAVIS_BRANCH" = "master" && "$TRAVIS_PULL_REQUEST" = "false" ]]; then
    echo "Squashing and pushing the :latest images to docker.io and quay.io"
    buildImages
    installDockerSquash
    loginDockerIo
    pushLatestImages "docker.io"
    loginQuayIo
    pushLatestImages "quay.io"
  elif [[ "${TRAVIS_TAG}" =~ ^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$ ]]; then
    echo "Squashing and pushing the '${TRAVIS_TAG}' images to docker.io and quay.io"
    buildImages
    installDockerSquash
    loginDockerIo
    pushReleaseImages "docker.io"
    loginQuayIo
    pushReleaseImages "quay.io"
  else
    echo "Not doing the docker push, because the tag '${TRAVIS_TAG}' is not of form x.y.z-n or we are not building the master branch"
  fi
}

buildImages() {
  BUILDER=docker make build
  BUILDER=docker make -f Makefile.inc build
}

loginDockerIo() {
  set +x
  docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
  set -x
}

loginQuayIo() {
  set +x
  docker login -u "$QUAY_USERNAME" -p "$QUAY_PASSWORD" quay.io
  set -x
}

installDockerSquash() {
  command -v docker-squash || pip install --user docker-squash
}

squashAndPush() {
  if [[ $# != 2 ]]; then
    echo "Usage: squashAndPush input_image output_image" && exit
  fi
  set +e
  local _in=$1
  local _out=$2

  local _layers_total=$(docker history -q $_in | wc -l)
  local _layers_to_keep=4

  if [[ ! "$_layers_total" =~ ^[0-9]+$ ]] || [[ "$_layers_total" -le "$_layers_to_keep" ]] ; then
    echo "error: _layers_total ('$_layers_total') is not a number or lower than or equal to $_layers_to_keep" >&2; return
  fi
  local _last_n=$[_layers_total - _layers_to_keep]

  echo "Squashing $_out (last $_last_n layers).."
  docker-squash -f $_last_n -t $_out $_in
  docker push $_out
  set -e
}

pushLatestImages() {
  if [[ $# != 1 ]]; then
    echo "Usage: pushLatestImages image_repo" && exit
  fi
  REPO="$1"

  for image in $IMAGES ; do
    squashAndPush $image "${REPO}/${OWNER}/${image}:latest"
  done
}

pushReleaseImages() {
  if [[ $# != 1 ]]; then
    echo "Usage: pushReleaseImages image_repo" && exit
  fi
  REPO="$1"

  for image in $IMAGES ; do
    local _fully_qualified_image="${REPO}/${OWNER}/${image}:${TRAVIS_TAG}"
    echo "Squashing $_fully_qualified_image.."

    squashAndPush $image $_fully_qualified_image

    # tag and push "x.y" image which acts as a "latest" for all  major.minor.Z versions
    local _x_y_latest=`echo ${TRAVIS_TAG} | sed -r 's;([[:digit:]]+\.[[:digit:]]+).*;\1;'`
    docker tag $_fully_qualified_image ${REPO}/${OWNER}/${image}:${_x_y_latest}
    docker push ${REPO}/${OWNER}/${image}:${_x_y_latest}

    # tag and push also :latest image
    docker tag $_fully_qualified_image ${REPO}/${OWNER}/${image}:latest
    docker push ${REPO}/${OWNER}/${image}:latest
  done

  docker logout
}

main
