#!/bin/sh

. /common.sh

# replace dashes with underscores
name=${1//-/_}
# write name resolution for spark-master
echo "$(eval echo \$${name^^}_SERVICE_HOST) spark-master" >> /tmp/hosts

# because the hostname only resolves locally
export SPARK_LOCAL_HOSTNAME=$(hostname -i)

spark-class org.apache.spark.deploy.worker.Worker spark://spark-master:7077
