#!/usr/bin/env bash

# Copies oc binary out of official openshift origin image
# Note:  this expects the OPENSHIFT_VERSION env variable to be set.
function download_openshift() {
  echo "Downloading oc binary for OPENSHIFT_VERSION=${OPENSHIFT_VERSION}"
  sudo docker cp $(docker create quay.io/openshift/origin-cli:$OPENSHIFT_VERSION):/bin/oc /usr/local/bin/oc
  oc version
}

function setup_insecure_registry() {
# add insecure-registry and restart docker
 sudo cat /etc/default/docker
 sudo service docker stop
 sudo sed -i -e 's/sock/sock --insecure-registry 172.30.0.0\/16/' /etc/default/docker
 sudo cat /etc/default/docker
 sudo service docker start
 sudo service docker status
}

function start_and_verify_openshift() {
  # Sometimes oc cluster up fails with a permission error and works when the test is relaunched.
  # See if a retry within the same test works
  set +e
  built=false
  while true; do
      oc cluster up --base-dir=/home/travis/gopath/src/github.com/radanalyticsio/origin
      if [ "$?" -eq 0 ]; then
          ./travis-check-pods.sh
          if [ "$?" -eq 0 ]; then
              built=true
              break
          fi
      fi
      echo "Retrying oc cluster up after failure"
      oc cluster down
      sleep 5
  done
  set -e
  if [ "$built" == false ]; then
      exit 1
  fi
  # travis-check-pods.sh left us in the default project
  oc project myproject
}

setup_insecure_registry
download_openshift
start_and_verify_openshift
