FROM centos:latest

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

RUN yum update -y && \
    yum install -y epel-release && \
    yum clean all

RUN yum install -y tar && \
    yum clean all

RUN cd /opt && \
    curl http://www.us.apache.org/dist/spark/spark-1.5.2/spark-1.5.2-bin-hadoop2.6.tgz | \
        tar -zx && \
    ln -s spark-1.5.2-bin-hadoop2.6 spark

RUN yum install -y java && \
    yum clean all

# when the containers are not run w/ uid 0, the uid may not map in
# /etc/passwd and it may not be possible to modify things like
# /etc/hosts. nss_wrapper provides an LD_PRELOAD way to modify passwd
# and hosts.
RUN yum install -y hostname nss_wrapper && yum clean all
ENV LD_PRELOAD=libnss_wrapper.so

ENV PATH $PATH:/opt/spark/bin

ADD common.sh /
RUN chmod a+rx /common.sh
