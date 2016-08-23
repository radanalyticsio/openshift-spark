#!/bin/bash

# spark likes to be able to lookup a username for the running UID, if
# no name is present fake it.
cat /etc/passwd > /tmp/passwd
echo "$(id -u):x:$(id -u):$(id -g):dynamic uid:$SPARK_HOME:/bin/false" >> /tmp/passwd

export NSS_WRAPPER_PASSWD=/tmp/passwd
# NSS_WRAPPER_GROUP must be set for NSS_WRAPPER_PASSWD to be used
export NSS_WRAPPER_GROUP=/etc/group

export LD_PRELOAD=libnss_wrapper.so

# If SPARK_MASTER_ADDRESS env varaible is not provided, start master,
# otherwise start worker and connect to SPARK_MASTER_ADDRESS
if [ -z ${SPARK_MASTER_ADDRESS+_} ]; then
    echo "Starting master"

    # run the spark master directly (instead of sbin/start-master.sh) to
    # link master and container lifecycle
    exec $SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master
else
    echo "Starting worker, will connect to: $SPARK_MASTER_ADDRESS"

    exec $SPARK_HOME/bin/spark-class org.apache.spark.deploy.worker.Worker $SPARK_MASTER_ADDRESS
fi

