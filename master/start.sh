#!/bin/sh

. /common.sh

echo "$(hostname -i) spark-master" >> /tmp/hosts

# start-master.sh uses SPARK_MATER_PORT and expects it to be an int, not a tcp:// url
export SPARK_MASTER_PORT=${SPARK_MASTER_SERVICE_PORT:-7077}

# run the spark master directly (instead of sbin/start-master.sh) to
# link master and container lifecycle
spark-class org.apache.spark.deploy.master.Master --ip spark-master --port 7077 --webui-port 8080
