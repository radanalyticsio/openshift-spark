#!/bin/bash

# If the UPDATE_SPARK_CONF_DIR dir is non-empty,
# copy the contents to $SPARK_HOME/conf
if [ -d "$UPDATE_SPARK_CONF_DIR" ]; then
    sparkconfs=$(ls -1 $UPDATE_SPARK_CONF_DIR | wc -l)
    if [ "$sparkconfs" -ne "0" ]; then
        echo "Copying from $UPDATE_SPARK_CONF_DIR to $SPARK_HOME/conf"
        ls -1 $UPDATE_SPARK_CONF_DIR
        cp $UPDATE_SPARK_CONF_DIR/* $SPARK_HOME/conf
    fi
elif [ -n "$UPDATE_SPARK_CONF_DIR" ]; then
    echo "Directory $UPDATE_SPARK_CONF_DIR does not exist, using default spark config"
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

