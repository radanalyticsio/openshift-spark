FROM centos:latest

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

RUN yum update -y && \
    yum install -y epel-release && \
    yum install -y yum-utils && \
    yum-config-manager --add-repo=http://ci.radanalytics.io/RAD/RAD-master.repo && \
    yum clean all
RUN yum install -y spark python-spark && yum clean all

# when the containers are not run w/ uid 0, the uid may not map in
# /etc/passwd and it may not be possible to modify things like
# /etc/hosts. nss_wrapper provides an LD_PRELOAD way to modify passwd
# and hosts.
RUN yum install -y nss_wrapper && yum clean all
ENV LD_PRELOAD=libnss_wrapper.so

ENV PATH $PATH:/usr/share/spark/bin

ADD common.sh /

# quiet the logging
RUN sed -i 's/log4j.rootCategory=.*/log4j.rootCategory=WARN, console/' \
     /usr/share/spark/conf/log4j.properties
