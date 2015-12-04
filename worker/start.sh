#!/bin/sh

. /common.sh

# name resolution for spark-master
echo "${SPARK_MASTER_SERVICE_HOST:-$1} spark-master" >> /tmp/hosts

# because the hostname only resolves locally
export SPARK_LOCAL_HOSTNAME=$(hostname -i)

spark-class org.apache.spark.deploy.worker.Worker spark://spark-master:7077
