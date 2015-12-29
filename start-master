#!/bin/sh

. /common.sh

# the name the master calls itself needs to be the same as what the
# workers call it. the workers use the spark-master-service name, and
# thus so shall the master.
echo "$(hostname -i) $1" >> /tmp/hosts
export SPARK_MASTER_HOST=$1

# run the spark master directly (instead of sbin/start-master.sh) to
# link master and container lifecycle
exec spark-class org.apache.spark.deploy.master.Master
