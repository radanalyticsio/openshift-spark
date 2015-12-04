#!/bin/sh

. /common.sh

# name resolution for spark-master
echo "${SPARK_MASTER_SERVICE_HOST:-$1} spark-master" >> /tmp/hosts

# because the hostname only resolves locally
export SPARK_LOCAL_HOSTNAME=$(hostname -i)

/usr/share/spark/sbin/start-slave.sh spark://spark-master:7077

# TODO: detect slave exit
tail -F /usr/share/spark/logs/*
