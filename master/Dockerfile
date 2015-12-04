FROM mattf/openshift-spark-base

MAINTAINER Matthew Farrellee <matt@cs.wisc.edu>

ADD start.sh /
RUN chmod a+rx /start.sh

EXPOSE 7077

ENTRYPOINT ["/start.sh"]
