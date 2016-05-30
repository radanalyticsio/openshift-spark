#!/bin/bash

# spark likes to be able to lookup a username for the running UID, if
# no name is present fake it.
if [[ ! $(getent passwd $(id -u)) ]]; then
  export SPARK_USER=$(id -u)
fi
