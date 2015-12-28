#!/bin/sh

. /common.sh

echo "$(hostname -i) $1" >> /tmp/hosts

unset SPARK_MASTER_PORT
unset SPARK_MASTER_WEBUI_PORT

# run the spark master directly (instead of sbin/start-master.sh) to
# link master and container lifecycle
spark-class org.apache.spark.deploy.master.Master --ip $1 --port 7077 --webui-port 8080
