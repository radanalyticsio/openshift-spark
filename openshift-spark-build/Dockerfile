
# This is a Dockerfile for the radanalyticsio/openshift-spark:3.0 image.


## START target image radanalyticsio/openshift-spark:3.0
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

###### START module 'spark:1.0'
###### \
        # Copy 'spark' module general artifacts to '/tmp/artifacts/' destination
        COPY \
            spark-3.2.0-bin-hadoop3.2.tgz \
            /tmp/artifacts/
        # Copy 'spark' module content
        COPY modules/spark /tmp/scripts/spark
        # Switch to 'root' user to install 'spark' module defined packages
        USER root
        # Install packages defined in the 'spark' module
        RUN yum --setopt=tsflags=nodocs install -y wget \
            && rpm -q wget
        # Set 'spark' module defined environment variables
        ENV \
            PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/spark/bin" \
            SPARK_HOME="/opt/spark" \
            SPARK_INSTALL="/opt/spark-distro" 
        # Custom scripts from 'spark' module
        USER root
        RUN [ "sh", "-x", "/tmp/scripts/spark/install" ]
###### /
###### END module 'spark:1.0'

###### START image 'radanalyticsio/openshift-spark:3.0'
###### \
        # Switch to 'root' user to install 'radanalyticsio/openshift-spark' image defined packages
        USER root
        # Install packages defined in the 'radanalyticsio/openshift-spark' image
        RUN yum --setopt=tsflags=nodocs install -y java-11-openjdk python3-numpy \
            && rpm -q java-11-openjdk python3-numpy
        # Set 'radanalyticsio/openshift-spark' image defined labels
        LABEL \
            io.cekit.version="3.12.0"  \
            io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"  \
            maintainer="Trevor McKay <tmckay@redhat.com>"  \
            sparkversion="3.2.0" 
###### /
###### END image 'radanalyticsio/openshift-spark:3.0'



    # Switch to 'root' user and remove artifacts and modules
    USER root
    RUN [ ! -d /tmp/scripts ] || rm -rf /tmp/scripts
    RUN [ ! -d /tmp/artifacts ] || rm -rf /tmp/artifacts
    # Clear package manager metadata
    RUN yum clean all && [ ! -d /var/cache/yum ] || rm -rf /var/cache/yum

    # Define the user
    USER 185
    # Define the working directory
    WORKDIR /tmp
    # Define entrypoint
    ENTRYPOINT ["/entrypoint"]
    # Define run cmd
    CMD ["/launch.sh"]
## /
## END target image