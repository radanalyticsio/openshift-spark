#!/bin/bash

function check_reverse_proxy {
    grep -e "^spark\.ui\.reverseProxy" $SPARK_HOME/conf/spark-defaults.conf &> /dev/null
    if [ "$?" -ne 0 ]; then
        echo "Appending default reverse proxy config to spark-defaults.conf"
        echo "spark.ui.reverseProxy              true" >> $SPARK_HOME/conf/spark-defaults.conf
        echo "spark.ui.reverseProxyUrl           /" >> $SPARK_HOME/conf/spark-defaults.conf
    fi
}

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

check_reverse_proxy

# If SPARK_MASTER_ADDRESS env varaible is not provided, start master,
# otherwise start worker and connect to SPARK_MASTER_ADDRESS
if [ -z ${SPARK_MASTER_ADDRESS+_} ]; then
    echo "Starting master"

    # run the spark master directly (instead of sbin/start-master.sh) to
    # link master and container lifecycle
    # If SPARK_METRICS_ON env variable is not provided, start master without the agent.
	if [ -z ${SPARK_METRICS_ON+_} ]; then
	    echo "Starting master"
	    # run the spark master directly (instead of sbin/start-master.sh) to
	    # link master and container lifecycle
	    exec $SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master
	else
	  echo "Starting master with metrics enabled"
		# If SPARK_METRICS_ON env is set then start spark master with agent
		exec $SPARK_HOME/bin/spark-class -javaagent:$SPARK_HOME/jolokia-jvm-1.3.6-agent.jar=port=7777,host=0.0.0.0 org.apache.spark.deploy.master.Master
	fi

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
    if [ -z ${SPARK_METRICS_ON+_} ]; then
        echo "Starting worker "
        exec $SPARK_HOME/bin/spark-class org.apache.spark.deploy.worker.Worker $SPARK_MASTER_ADDRESS
    else
        echo "Starting worker with metrics enabled "
        exec $SPARK_HOME/bin/spark-class -javaagent:$SPARK_HOME/jolokia-jvm-1.3.6-agent.jar=port=7777,host=0.0.0.0 org.apache.spark.deploy.worker.Worker $SPARK_MASTER_ADDRESS
    fi
fi
