#!/bin/sh

export SPARK_PUBLIC_DNS=${SPARK_MASTER_SERVICE_HOST:-$1}

/usr/share/spark/sbin/start-master.sh
PID=$(cat /tmp/spark-*.pid)

while kill -0 $PID; do sleep 34; done
