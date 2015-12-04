#!/bin/sh

. /common.sh

echo "$(hostname -i) spark-master" >> /tmp/hosts

unset SPARK_MASTER_PORT
unset SPARK_MASTER_WEBUI_PORT

# run the spark master directly (instead of sbin/start-master.sh) to
# link master and container lifecycle
spark-class org.apache.spark.deploy.master.Master --ip spark-master --port 7077 --webui-port 8080
