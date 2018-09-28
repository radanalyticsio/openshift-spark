# radanalyticsio/openshift-spark-inc

## Description




## Environment variables

### Informational

These environment variables are defined in the image.

__PATH__
>"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/spark/bin"

__SCL_ENABLE_CMD__
>"scl enable rh-python36"

__SPARK_HOME__
>"/opt/spark"

__SPARK_INSTALL__
>"/opt/spark-distro"

__STI_SCRIPTS_PATH__
>"/usr/libexec/s2i"


### Configuration

The image can be configured by defining these environment variables
when starting a container:



## Labels

__io.cekit.version__
> 2.1.4

__io.openshift.s2i.scripts-url__
> image:///usr/libexec/s2i

__maintainer__
> Chad Roberts <croberts@redhat.com>

__org.concrt.version__
> 2.1.4

__sparkversion__
> 2.3.0


