#!/bin/sh

while getopts "m:" opt; do
  case $opt in
    m)
      master=$OPTARG
      ;;
  esac
done

if [ -z "$master" ]; then
  echo "No master provided, -m required, e.g. -m spark-master.local" >&2
  exit 1
fi

echo "Starting worker, will connect to: $master"

. /common.sh

# because the hostname only resolves locally
export SPARK_LOCAL_HOSTNAME=$(hostname -i)

spark-class org.apache.spark.deploy.worker.Worker $master
