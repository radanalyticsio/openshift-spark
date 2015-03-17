#!/bin/sh

MASTER_IP=${SPARK_MASTER_SERVICE_HOST:-$1}
echo "MASTER_IP=$MASTER_IP"

# name resolution for spark-master
echo "$MASTER_IP spark-master" >> /etc/hosts

/usr/share/spark/sbin/start-slave.sh 1 spark://spark-master:7077

tail -F /usr/share/spark/logs/*
