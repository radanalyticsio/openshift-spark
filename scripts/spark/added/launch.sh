#!/bin/bash

# spark likes to be able to lookup a username for the running UID, if
# no name is present fake it.
cat /etc/passwd > /tmp/passwd
echo "$(id -u):x:$(id -u):$(id -g):dynamic uid:$SPARK_HOME:/bin/false" >> /tmp/passwd

export NSS_WRAPPER_PASSWD=/tmp/passwd
# NSS_WRAPPER_GROUP must be set for NSS_WRAPPER_PASSWD to be used
export NSS_WRAPPER_GROUP=/etc/group

export LD_PRELOAD=libnss_wrapper.so

# If the /etc/oshinko-spark-configs dir is non-empty,
# copy the contents to $SPARK_HOME/conf
USER_SPARK_CONF=/etc/oshinko-spark-configs
ls -1 $USER_SPARK_CONF &> /dev/null
if [ $? -eq 0 ]; then
    sparkconfs=$(ls -1 /etc/oshinko-spark-configs | wc -l)
    if [ "$sparkconfs" -ne "0" ]; then
        echo "Copying $USER_SPARK_CONF/* to $SPARK_HOME/conf"
        ls -1 /etc/oshinko-spark-configs
        cp $USER_SPARK_CONF/* $SPARK_HOME/conf
    fi
else
    echo "/etc/oshinko-spark-configs does not exist, using default spark config"
fi

# If SPARK_MASTER_ADDRESS env varaible is not provided, start master,
# otherwise start worker and connect to SPARK_MASTER_ADDRESS
if [ -z ${SPARK_MASTER_ADDRESS+_} ]; then
    echo "Starting master"

    # run the spark master directly (instead of sbin/start-master.sh) to
    # link master and container lifecycle
    exec $SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master
else
    echo "Starting worker, will connect to: $SPARK_MASTER_ADDRESS"
    while true; do
        echo "Waiting for spark master to be available ..."
        curl --connect-timeout 1 -s -X GET $SPARK_MASTER_UI_ADDRESS > /dev/null
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 1
    done
    exec $SPARK_HOME/bin/spark-class org.apache.spark.deploy.worker.Worker $SPARK_MASTER_ADDRESS
fi

