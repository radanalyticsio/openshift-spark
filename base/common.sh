#!/bin/bash

# spark likes to be able to lookup a username for the running UID, if
# no name is present fake it. it may also be possible to use the
# SPARK_USER environment variable.
if [[ ! $(getent passwd $(id -u)) ]]; then
  cat /etc/passwd > /tmp/passwd
  echo "$(id -u):x:$(id -u):$(id -g):dynamic uid:/opt/spark:/bin/false" >> /tmp/passwd
  export NSS_WRAPPER_PASSWD=/tmp/passwd
fi

# nss wrapper does not handle comments
grep -v ^# /etc/hosts > /tmp/hosts
export NSS_WRAPPER_HOSTS=/tmp/hosts
