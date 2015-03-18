#!/bin/sh

# start-master.sh uses SPARK_MATER_PORT and expects it to be an int, not a tcp:// url
export SPARK_MASTER_PORT=${SPARK_MASTER_SERVICE_PORT:-7077}

/usr/share/spark/sbin/start-master.sh

# TODO: detect master exit
tail -F /usr/share/spark/logs/*
