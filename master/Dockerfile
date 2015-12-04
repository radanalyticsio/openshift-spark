FROM mattf/openshift-spark-base

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

ADD start.sh /
RUN chmod a+rx /start.sh

# place SPARK_LOG_DIR in a location that can be created and written to
ENV SPARK_LOG_DIR=/tmp/logs

EXPOSE 7077 8080

ENTRYPOINT ["/start.sh"]
