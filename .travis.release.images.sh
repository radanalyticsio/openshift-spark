#!/bin/bash
  
set -xe

OWNER="${OWNER:-radanalyticsio}"
IMAGES="${IMAGES:-
  openshift-spark
  openshift-spark-py36
  openshift-spark-inc
  openshift-spark-py36-inc
}"

main() {
  if [[ "$TRAVIS_BRANCH" = "master" -a "$TRAVIS_PULL_REQUEST" = "false" ]]; then
    echo "Squashing and pushing the :latest images to docker.io and quay.io"
    installDockerSquash
    loginDockerIo
    pushLatestImages "docker.io"
    loginQuayIo
    pushLatestImages "quay.io"
  elif [[ "${TRAVIS_TAG}" =~ ^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$ ]]; then
    echo "Squashing and pushing the '${TRAVIS_TAG}' images to docker.io and quay.io"
    installDockerSquash
    loginDockerIo
    pushReleaseImages "docker.io"
    loginQuayIo
    pushReleaseImages "quay.io"
  else
    echo "Not doing the docker push, because the tag '${TRAVIS_TAG}' is not of form x.y.z-n or we are not building the master branch"
  fi
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
  if [[ $# != 3 ]]; then
    echo "Usage: squashAndPush input_image output_image" && exit
  fi
  local _in=$1
  local _out=$2

  echo "Squashing $_out.."
  # squash last 22 layers (everything up to the base centos image)
  docker-squash -f 22 -t $_out $in
  docker push $_out
}

pushLatestImages() {
  if [[ $# != 2 ]]; then
    echo "Usage: pushLatestImages image_repo" && exit
  fi
  REPO="$1"

  for image in $IMAGES ; do
    squashAndPush $image "${REPO}/${OWNER}/${image}:latest"
  done
}

pushReleaseImages() {
  if [[ $# != 2 ]]; then
    echo "Usage: pushReleaseImages image_repo" && exit
  fi
  REPO="$1"

  for image in $IMAGES ; do
    local _fully_qualified_image="${REPO}/${OWNER}/${image}:${TRAVIS_TAG}"
    echo "Squashing $_fully_qualified_image.."

    squashAndPush $image $_fully_qualified_image

    # tag and push also x.y-latest image
    local _x_y_z_latest=`echo ${TRAVIS_TAG} | sed -r 's;([[:digit:]]+\.[[:digit:]]+).*;\1-latest;'`
    docker tag $_fully_qualified_image ${REPO}/${OWNER}/${image}:${_x_y_z_latest}
    docker push ${REPO}/${OWNER}/${image}:${_x_y_z_latest}

    # tag and push also :latest image
    docker tag $_fully_qualified_image ${REPO}/${OWNER}/${image}:latest
    docker push ${REPO}/${OWNER}/${image}:latest
  done

  docker logout
}

main
