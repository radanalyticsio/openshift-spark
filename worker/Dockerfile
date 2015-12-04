FROM openshift-spark-base

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

ADD start.sh /
RUN chmod a+rx /start.sh

# place SPARK_WORKER_DIR (worker's --work-dir) in a location that can
# be created and written to
ENV SPARK_WORKER_DIR=/tmp/work

EXPOSE 8888

ENTRYPOINT ["/start.sh"]
