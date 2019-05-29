# Copyright 2017 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ------------------------------------------------------------------------
#
# This is a Dockerfile for the radanalyticsio/openshift-spark-inc:2.4-latest image.

FROM centos:latest

USER root


# Install required RPMs and ensure that the packages were installed
RUN yum install -y java-1.8.0-openjdk wget rsync numpy \
    && yum clean all && rm -rf /var/cache/yum \
    && rpm -q java-1.8.0-openjdk wget rsync numpy



# Environment variables
ENV \
    JBOSS_IMAGE_NAME="radanalyticsio/openshift-spark-inc" \
    JBOSS_IMAGE_VERSION="2.4-latest" \
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/spark/bin" \
    SCL_ENABLE_CMD="" \
    SPARK_HOME="/opt/spark" \
    SPARK_INSTALL="/opt/spark-distro" \
    STI_SCRIPTS_PATH="/usr/libexec/s2i" 

# Labels
LABEL \
      io.cekit.version="2.2.7"  \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"  \
      maintainer="Chad Roberts <croberts@redhat.com>"  \
      name="radanalyticsio/openshift-spark-inc"  \
      org.concrt.version="2.2.7"  \
      sparkversion="2.4.0"  \
      version="2.4-latest" 

# Add scripts used to configure the image
COPY modules /tmp/scripts

# Custom scripts
USER root
RUN [ "bash", "-x", "/tmp/scripts/common/install" ]

USER root
RUN [ "bash", "-x", "/tmp/scripts/metrics/install" ]

USER root
RUN [ "bash", "-x", "/tmp/scripts/s2i/install" ]

USER root
RUN rm -rf /tmp/scripts

USER 185


ENTRYPOINT ["/entrypoint"]

CMD ["/usr/libexec/s2i/usage"]

