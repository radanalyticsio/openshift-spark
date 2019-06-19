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

if [ -z ${SPARK_METRICS_ON+_} ]; then
    JAVA_AGENT=
    metrics=""
elif [ ${SPARK_METRICS_ON} == "prometheus" ]; then
    JAVA_AGENT=" -javaagent:/opt/metrics/agent-bond.jar=$SPARK_HOME/conf/agent.properties"
    metrics=" with prometheus metrics enabled"
else
    JAVA_AGENT=" -javaagent:/opt/metrics/jolokia-jvm-1.3.6-agent.jar=port=7777,host=0.0.0.0"
    metrics=" with jolokia metrics enabled (deprecated, set SPARK_METRICS_ON to 'prometheus')"
fi

if [ -z ${SPARK_MASTER_ADDRESS+_} ]; then
    echo "Starting master$metrics"
    exec $SPARK_HOME/bin/spark-class$JAVA_AGENT org.apache.spark.deploy.master.Master
else
    echo "Starting worker$metrics, will connect to: $SPARK_MASTER_ADDRESS"
    while true; do
        echo "Waiting for spark master to be available ..."
        curl --connect-timeout 1 -s -X GET $SPARK_MASTER_UI_ADDRESS > /dev/null
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 1
    done
    exec $SPARK_HOME/bin/spark-class$JAVA_AGENT org.apache.spark.deploy.worker.Worker $SPARK_MASTER_ADDRESS
fi
