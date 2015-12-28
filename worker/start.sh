#!/bin/sh

. /common.sh

# because the hostname only resolves locally
export SPARK_LOCAL_HOSTNAME=$(hostname -i)

spark-class org.apache.spark.deploy.worker.Worker spark://$1:7077
