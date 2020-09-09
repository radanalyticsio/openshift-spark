# Copyright 2019 Red Hat
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
# This is a Dockerfile for the radanalyticsio/openshift-spark-inc:3.0 image.


## START target image radanalyticsio/openshift-spark-inc:3.0
## \
    FROM centos:8

    USER root

###### START module 'common:1.0'
###### \
        # Copy 'common' module content
        COPY modules/common /tmp/scripts/common
        # Switch to 'root' user to install 'common' module defined packages
        USER root
        # Install packages defined in the 'common' module
        RUN yum --setopt=tsflags=nodocs install -y python36 \
            && rpm -q python36
        # Set 'common' module defined environment variables
        ENV \
            SPARK_INSTALL="/opt/spark-distro" 
        # Custom scripts from 'common' module
        USER root
        RUN [ "sh", "-x", "/tmp/scripts/common/install" ]
###### /
###### END module 'common:1.0'

###### START module 'metrics:1.0'
###### \
        # Copy 'metrics' module content
        COPY modules/metrics /tmp/scripts/metrics
        # Custom scripts from 'metrics' module
        USER root
        RUN [ "sh", "-x", "/tmp/scripts/metrics/install" ]
###### /
###### END module 'metrics:1.0'

###### START module 's2i:1.0'
###### \
        # Copy 's2i' module content
        COPY modules/s2i /tmp/scripts/s2i
        # Switch to 'root' user to install 's2i' module defined packages
        USER root
        # Install packages defined in the 's2i' module
        RUN yum --setopt=tsflags=nodocs install -y wget \
            && rpm -q wget
        # Set 's2i' module defined environment variables
        ENV \
            PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/spark/bin" \
            SPARK_HOME="/opt/spark" \
            SPARK_INSTALL="/opt/spark-distro" \
            STI_SCRIPTS_PATH="/usr/libexec/s2i" 
        # Custom scripts from 's2i' module
        USER root
        RUN [ "sh", "-x", "/tmp/scripts/s2i/install" ]
###### /
###### END module 's2i:1.0'

###### START image 'radanalyticsio/openshift-spark-inc:3.0'
###### \
        # Switch to 'root' user to install 'radanalyticsio/openshift-spark-inc' image defined packages
        USER root
        # Install packages defined in the 'radanalyticsio/openshift-spark-inc' image
        RUN yum --setopt=tsflags=nodocs install -y java-11-openjdk rsync \
            && rpm -q java-11-openjdk rsync
        # Set 'radanalyticsio/openshift-spark-inc' image defined environment variables
        ENV \
            JBOSS_IMAGE_NAME="radanalyticsio/openshift-spark-inc" \
            JBOSS_IMAGE_VERSION="3.0" 
        # Set 'radanalyticsio/openshift-spark-inc' image defined labels
        LABEL \
            io.cekit.version="3.6.0"  \
            io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"  \
            maintainer="Trevor McKay <tmckay@redhat.com>"  \
            name="radanalyticsio/openshift-spark-inc"  \
            version="3.0" 
###### /
###### END image 'radanalyticsio/openshift-spark-inc:3.0'


    # Switch to 'root' user and remove artifacts and modules
    USER root
    RUN [ ! -d /tmp/scripts ] || rm -rf /tmp/scripts
    RUN [ ! -d /tmp/artifacts ] || rm -rf /tmp/artifacts

    # Clear package manager metadata
    RUN yum clean all && [ ! -d /var/cache/yum ] || rm -rf /var/cache/yum

    # Define the user
    USER 185
    # Define entrypoint
    ENTRYPOINT ["/entrypoint"]
    # Define run cmd
    CMD ["/usr/libexec/s2i/usage"]
## /
## END target image