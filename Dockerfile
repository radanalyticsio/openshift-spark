FROM centos:latest

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

USER root
ARG DISTRO_LOC=https://dist.apache.org/repos/dist/release/spark/spark-2.1.0/spark-2.1.0-bin-hadoop2.7.tgz
ARG DISTRO_NAME=spark-2.1.0-bin-hadoop2.7

RUN yum install -y epel-release tar java && \
    yum clean all

RUN cd /opt && \
    curl $DISTRO_LOC  | \
        tar -zx && \
    ln -s $DISTRO_NAME spark

# when the containers are not run w/ uid 0, the uid may not map in
# /etc/passwd and it may not be possible to modify things like
# /etc/hosts. nss_wrapper provides an LD_PRELOAD way to modify passwd
# and hosts.
RUN yum install -y nss_wrapper numpy && yum clean all

ENV PATH=$PATH:/opt/spark/bin
ENV SPARK_HOME=/opt/spark

# Add scripts used to configure the image
COPY scripts /tmp/scripts

# Adding jmx by default
COPY metrics /opt/spark
RUN mv $SPARK_HOME/metrics.properties $SPARK_HOME/conf/metrics.properties && chown 1000 /opt/spark/conf/metrics.properties && chmod a+rwx /opt/spark/jolokia-jvm-1.3.6-agent.jar && chown 1000 /opt/spark/jolokia-jvm-1.3.6-agent.jar



# Custom scripts
RUN [ "bash", "-x", "/tmp/scripts/spark/install" ]

# Cleanup the scripts directory
RUN rm -rf /tmp/scripts

# Switch to the user 185 for OpenShift usage
USER 185

# Make the default PWD somewhere that the user can write. This is
# useful when connecting with 'oc run' and starting a 'spark-shell',
# which will likely try to create files and directories in PWD and
# error out if it cannot.
WORKDIR /tmp

ENTRYPOINT ["/entrypoint"]

# Start the main process
CMD ["/opt/spark/bin/launch.sh"]
