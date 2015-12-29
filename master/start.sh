#!/bin/sh

while getopts "n:" opt; do
  case $opt in
    n)
      name=$OPTARG
      ;;
  esac
done

if [ -z "$name" ]; then
  echo "No name provided, -n required, e.g. -n spark-master.local" >&2
  exit 1
fi

echo "Starting master, using name: $name"

. /common.sh

# the name the master calls itself needs to be the same as what the
# workers call it. the workers use the spark-master-service name, and
# thus so shall the master.
echo "$(hostname -i) $name" >> /tmp/hosts

# unset these env variables that are used by the Master, because they
# may be set and if so they're likely to be set to kubernetes
# specified values instead of values Master can understand. for
# instance, SPARK_MASTER_PORT=tcp://172.30.74.44:7077 instead of just
# 7077.
unset SPARK_MASTER_PORT
unset SPARK_MASTER_WEBUI_PORT

# run the spark master directly (instead of sbin/start-master.sh) to
# link master and container lifecycle
spark-class org.apache.spark.deploy.master.Master --ip $name --port 7077 --webui-port 8080
