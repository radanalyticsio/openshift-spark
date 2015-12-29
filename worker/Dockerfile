FROM openshift-spark-base

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

ADD start.sh /
RUN chmod a+rx /start.sh

# the Worker tries to create SPARK_WORKER_DIR on startup, defaults to
# SPARK_HOME/work.
RUN mkdir /opt/spark/work && chmod a+rwx /opt/spark/work

ENTRYPOINT ["/start.sh"]
