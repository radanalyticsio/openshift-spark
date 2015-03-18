#!/bin/sh

# name resolution for spark-master
echo "${SPARK_MASTER_SERVICE_HOST:-$1} spark-master" >> /etc/hosts

/usr/share/spark/sbin/start-slave.sh 1 spark://spark-master:7077

tail -F /usr/share/spark/logs/*
