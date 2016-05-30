FROM centos:latest

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

RUN yum install -y epel-release tar java && \
    yum clean all

RUN cd /opt && \
    curl https://dist.apache.org/repos/dist/release/spark/spark-2.0.0-preview/spark-2.0.0-preview-bin-hadoop2.7.tgz | \
        tar -zx && \
    ln -s spark-2.0.0-preview-bin-hadoop2.7 spark

# SPARK_WORKER_DIR defaults to SPARK_HOME/work and is created on
# Worker startup if it does not exist. instead of making SPARK_HOME
# world writable, create SPARK_HOME/work.
RUN mkdir /opt/spark/work && chmod a+rwx /opt/spark/work

ENV PATH $PATH:/opt/spark/bin

ADD common.sh start-master start-worker /
RUN chmod a+rx /common.sh /start-master /start-worker
