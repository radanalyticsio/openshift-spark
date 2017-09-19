FROM centos:latest

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

USER root

# when changing the version, don't forget also to change the sha1 checksum
ARG DISTRO_LOC=https://archive.apache.org/dist/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz

ENV PATH="$PATH:/opt/spark/bin" \
    TINI_VERSION=v0.16.1 \
    PATH="$PATH:/opt/spark/bin" \
    SPARK_HOME="/opt/spark"

# Add scripts used to configure the image
COPY scripts /tmp/scripts

# Adding jmx by default
COPY metrics /tmp/spark

RUN yum install -y epel-release tar wget java numpy && \
    cd /opt && \
    chmod a+rw /etc/passwd && \
    curl -O --progress-bar $DISTRO_LOC && \
    echo "e48dd30a62f8e6cf87920d931564929d00780a29 `ls spark-*`" | sha1sum -c - && \
    tar -zxf spark-* && \
    rm -rf spark-*.tgz && \
    ln -s spark-* spark && \
    mv /tmp/spark/* spark/ && \
    bash -x /tmp/scripts/spark/install && \
    rm -rf /tmp/scripts && \
    wget -q https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -P /tmp && \
    wget -q https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc -P /tmp && \
    cd /tmp  && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 0527A9B7 && gpg --verify /tmp/tini.asc && \
    mv /tmp/tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini && \
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
