#!/bin/sh

. /common.sh

# nss wrapper does not handle comments
grep -v ^# /etc/hosts > /tmp/hosts
echo "$(hostname -i) spark-master" >> /tmp/hosts
export NSS_WRAPPER_HOSTS=/tmp/hosts

# start-master.sh uses SPARK_MATER_PORT and expects it to be an int, not a tcp:// url
export SPARK_MASTER_PORT=${SPARK_MASTER_SERVICE_PORT:-7077}

/usr/share/spark/sbin/start-master.sh

# TODO: detect master exit
tail -F /usr/share/spark/logs/*
