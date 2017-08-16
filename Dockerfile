FROM centos:latest

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

USER root

# when changing the version, don't forget also to change the sha1 checksum
ARG DISTRO_LOC=https://archive.apache.org/dist/spark/spark-2.1.0/spark-2.1.0-bin-hadoop2.7.tgz

ENV PATH="$PATH:/opt/spark/bin" \
    SPARK_HOME="/opt/spark"

# Add scripts used to configure the image
COPY scripts /tmp/scripts

# Adding jmx by default
COPY metrics /tmp/spark

# when the containers are not run w/ uid 0, the uid may not map in
# /etc/passwd and it may not be possible to modify things like
# /etc/hosts. nss_wrapper provides an LD_PRELOAD way to modify passwd
# and hosts. nss_wrapper package needs to be installed in its own step
RUN yum install -y epel-release tar java numpy && \
    yum install -y nss_wrapper && \
    cd /opt && \
    curl -O --progress-bar $DISTRO_LOC && \
    echo "9d1188efbbc92ba6aa0b834ea684d00fa7b63e39 `ls spark-*`" | sha1sum -c - && \
    tar -zxf spark-* && \
    rm -rf spark-*.tgz && \
    ln -s spark-* spark && \
    mv /tmp/spark/* spark/ && \
    bash -x /tmp/scripts/spark/install && \
    rm -rf /tmp/scripts && \
    yum clean all

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
