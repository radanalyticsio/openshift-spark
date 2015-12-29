#!/bin/bash

# spark likes to be able to lookup a username for the running UID, if
# no name is present fake it. it may also be possible to use the
# SPARK_USER environment variable.
if [[ ! $(getent passwd $(id -u)) ]]; then
  if [[ ! -e /tmp/passwd ]]; then
    cat /etc/passwd > /tmp/passwd
    echo "$(id -u):x:$(id -u):$(id -g):dynamic uid:/opt/spark:/bin/false" >> /tmp/passwd
  fi
fi

# nss wrapper does not handle comments
if [[ ! -e /tmp/hosts ]]; then
  grep -v ^# /etc/hosts > /tmp/hosts
fi

export NSS_WRAPPER_PASSWD=/tmp/passwd
# NSS_WRAPPER_GROUP must be set for NSS_WRAPPER_PASSWD to be used
export NSS_WRAPPER_GROUP=/etc/group
export NSS_WRAPPER_HOSTS=/tmp/hosts
