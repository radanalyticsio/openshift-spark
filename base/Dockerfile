FROM centos:latest

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

RUN yum update -y && \
    yum install -y yum-utils && \
    yum-config-manager --add-repo=http://ci.radanalytics.io/RAD/RAD-master.repo && \
    yum clean all
RUN yum install -y spark python-spark && yum clean all

ENV PATH $PATH:/usr/share/spark/bin

# quiet the logging
RUN sed -i 's/log4j.rootCategory=.*/log4j.rootCategory=WARN, console/' \
     /usr/share/spark/conf/log4j.properties
