#!/bin/sh

export SPARK_PUBLIC_DNS=${SPARK_MASTER_SERVICE_HOST:-$1}

/usr/share/spark/sbin/start-master.sh

tail -F /usr/share/spark/logs/*
