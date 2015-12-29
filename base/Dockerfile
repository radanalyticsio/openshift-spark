FROM centos:latest

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

RUN yum update -y && \
    yum install -y epel-release tar java && \
    yum clean all

RUN cd /opt && \
    curl http://www.us.apache.org/dist/spark/spark-1.5.2/spark-1.5.2-bin-hadoop2.6.tgz | \
        tar -zx && \
    ln -s spark-1.5.2-bin-hadoop2.6 spark

# SPARK_WORKER_DIR defaults to SPARK_HOME/work and is created on
# Worker startup if it does not exist. instead of making SPARK_HOME
# world writable, create SPARK_HOME/work.
RUN mkdir /opt/spark/work && chmod a+rwx /opt/spark/work

# when the containers are not run w/ uid 0, the uid may not map in
# /etc/passwd and it may not be possible to modify things like
# /etc/hosts. nss_wrapper provides an LD_PRELOAD way to modify passwd
# and hosts.
RUN yum install -y hostname nss_wrapper && yum clean all
ENV LD_PRELOAD=libnss_wrapper.so

ENV PATH $PATH:/opt/spark/bin

ADD common.sh /
RUN chmod a+rx /common.sh
