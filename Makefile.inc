LOCAL_IMAGE ?= openshift-spark-inc
SPARK_IMAGE=radanalyticsio/openshift-spark-inc
BUILDER ?= podman

DOCKERFILE_CONTEXT=openshift-spark-build-inc

SPARK_TEST_IMAGE ?= spark-testimage-inc

export SPARK_TEST_IMAGE

.PHONY: build clean push create destroy test-e2e test-e2e-completed

build: $(DOCKERFILE_CONTEXT)
	$(BUILDER) build -t $(LOCAL_IMAGE) $(DOCKERFILE_CONTEXT)

push: build
	$(BUILDER) tag $(LOCAL_IMAGE) $(SPARK_IMAGE)
	$(BUILDER) push $(SPARK_IMAGE)

clean: clean-context
	-$(BUILDER) rmi $(LOCAL_IMAGE)

clean-target:
	-rm -rf target

clean-context:
	-rm -rf $(DOCKERFILE_CONTEXT)/*

context: $(DOCKERFILE_CONTEXT)

$(DOCKERFILE_CONTEXT): $(DOCKERFILE_CONTEXT)/Dockerfile $(DOCKERFILE_CONTEXT)/modules

$(DOCKERFILE_CONTEXT)/Dockerfile $(DOCKERFILE_CONTEXT)/modules:
	-mkdir -p $(DOCKERFILE_CONTEXT)
	cekit --descriptor image-inc.yaml build --dry-run $(BUILDER)
	cp -R target/image/* $(DOCKERFILE_CONTEXT)
	-rm $(DOCKERFILE_CONTEXT)/spark*.tgz

zero-tarballs:
	find ./$(DOCKERFILE_CONTEXT) -name "*.tgz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT) -name "*.tar.gz" -type f -exec truncate -s 0 {} \;

test-e2e:
	test/sparkinputs.sh
	LOCAL_IMAGE=$(SPARK_TEST_IMAGE) make -f Makefile.inc build
	SPARK_TEST_IMAGE=$(SPARK_TEST_IMAGE) test/run.sh incomplete/

test-e2e-completed:
	test/sparkinputs.sh
	LOCAL_IMAGE=$(SPARK_TEST_IMAGE) make -f Makefile.inc build
	test/localcomplete.sh $(SPARK_TEST_IMAGE) spark-complete
	SPARK_TEST_IMAGE=spark-complete test/run.sh completed/
