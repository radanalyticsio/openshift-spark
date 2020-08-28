# This is a Dockerfile for the radanalyticsio/openshift-spark-inc:2.4-latest image.


## START target image radanalyticsio/openshift-spark-inc:2.4-latest
## \
    FROM centos:7

    USER root

###### START module 'common:1.0'
###### \
        # Copy 'common' module content
        COPY modules/common /tmp/scripts/common
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
        # Set 's2i' module defined environment variables
        ENV \
            STI_SCRIPTS_PATH="/usr/libexec/s2i" 
        # Custom scripts from 's2i' module
        USER root
        RUN [ "sh", "-x", "/tmp/scripts/s2i/install" ]
###### /
###### END module 's2i:1.0'

###### START image 'radanalyticsio/openshift-spark-inc:2.4-latest'
###### \
        # Switch to 'root' user to install 'radanalyticsio/openshift-spark-inc' image defined packages
        USER root
        # Install packages defined in the 'radanalyticsio/openshift-spark-inc' image
        RUN yum --setopt=tsflags=nodocs install -y java-1.8.0-openjdk wget rsync numpy \
            && rpm -q java-1.8.0-openjdk wget rsync numpy
        # Set 'radanalyticsio/openshift-spark-inc' image defined environment variables
        ENV \
            JBOSS_IMAGE_NAME="radanalyticsio/openshift-spark-inc" \
            JBOSS_IMAGE_VERSION="2.4-latest" 
        # Set 'radanalyticsio/openshift-spark-inc' image defined labels
        LABEL \
            io.cekit.version="3.7.0"  \
            io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"  \
            maintainer="Chad Roberts <croberts@redhat.com>"  \
            name="radanalyticsio/openshift-spark-inc"  \
            version="2.4-latest" 
###### /
###### END image 'radanalyticsio/openshift-spark-inc:2.4-latest'


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