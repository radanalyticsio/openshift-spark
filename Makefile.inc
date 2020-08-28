LOCAL_IMAGE ?= openshift-spark-inc
SPARK_IMAGE=radanalyticsio/openshift-spark-inc

LOCAL_IMAGE_PY27 ?= openshift-spark-py27-inc
SPARK_IMAGE_PY27=radanalyticsio/openshift-spark-py27-inc

DOCKERFILE_CONTEXT=openshift-spark-build-inc
DOCKERFILE_CONTEXT_PY27=openshift-spark-build-py27-inc

SPARK_TEST_IMAGE ?= spark-testimage-inc
SPARK_TEST_IMAGE_PY27 ?= spark-testimage-py27-inc

export SPARK_TEST_IMAGE

.PHONY: build clean push create destroy test-e2e test-e2e-py test-e2e-py-completed test-e2e-py27 test-e2e-py27-completed build-py build-py27

build: build-py build-py27

build-py: $(DOCKERFILE_CONTEXT)
	podman build -t $(LOCAL_IMAGE) $(DOCKERFILE_CONTEXT)

build-py27: $(DOCKERFILE_CONTEXT_PY27)
	podman build -t $(LOCAL_IMAGE_PY27) $(DOCKERFILE_CONTEXT_PY27)

push: build
	podman tag $(LOCAL_IMAGE) $(SPARK_IMAGE)
	podman push $(SPARK_IMAGE)
	podman tag $(LOCAL_IMAGE_PY27) $(SPARK_IMAGE_PY27)
	podman push $(SPARK_IMAGE_PY27)

clean: clean-context
	-podman rmi $(LOCAL_IMAGE)
	-podman rmi $(LOCAL_IMAGE_PY27)

clean-target:
	-rm -rf target
	-rm -rf target-py27

clean-context:
	-rm -rf $(DOCKERFILE_CONTEXT)/*
	-rm -rf $(DOCKERFILE_CONTEXT_PY27)/*

context: $(DOCKERFILE_CONTEXT) $(DOCKERFILE_CONTEXT_PY27)

$(DOCKERFILE_CONTEXT): $(DOCKERFILE_CONTEXT)/Dockerfile $(DOCKERFILE_CONTEXT)/modules

$(DOCKERFILE_CONTEXT_PY27): $(DOCKERFILE_CONTEXT_PY27)/Dockerfile $(DOCKERFILE_CONTEXT_PY27)/modules

$(DOCKERFILE_CONTEXT)/Dockerfile $(DOCKERFILE_CONTEXT)/modules:
	-mkdir -p $(DOCKERFILE_CONTEXT)
	cekit --descriptor image-inc.yaml build --overrides overrides/python-inc.yaml podman
	cp -R target/image/* $(DOCKERFILE_CONTEXT)
	-rm $(DOCKERFILE_CONTEXT)/spark*.tgz

$(DOCKERFILE_CONTEXT_PY27)/Dockerfile $(DOCKERFILE_CONTEXT_PY27)/modules:
	-mkdir -p $(DOCKERFILE_CONTEXT_PY27)
	cekit --descriptor image-inc.yaml --target target-py27 build --overrides overrides/python27-inc.yaml podman
	cp -R target-py27/image/* $(DOCKERFILE_CONTEXT_PY27)
	-rm $(DOCKERFILE_CONTEXT_PY27)/spark*.tgz

zero-tarballs:
	find ./$(DOCKERFILE_CONTEXT) -name "*.tgz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT) -name "*.tar.gz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT_PY27) -name "*.tgz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT_PY27) -name "*.tar.gz" -type f -exec truncate -s 0 {} \;

test-e2e:
	test/sparkinputs.sh
	LOCAL_IMAGE=$(SPARK_TEST_IMAGE) LOCAL_IMAGE_PY27=$(SPARK_TEST_IMAGE_PY27) make -f Makefile.inc build
	SPARK_TEST_IMAGE=$(SPARK_TEST_IMAGE) test/run.sh incomplete/
	SPARK_TEST_IMAGE=$(SPARK_TEST_IMAGE_PY27) test/run.sh incomplete/

test-e2e-py:
	test/sparkinputs.sh
	LOCAL_IMAGE=$(SPARK_TEST_IMAGE) make -f Makefile.inc build-py
	SPARK_TEST_IMAGE=$(SPARK_TEST_IMAGE) test/run.sh incomplete/

test-e2e-py-completed:
	test/sparkinputs.sh
	LOCAL_IMAGE=$(SPARK_TEST_IMAGE) make -f Makefile.inc build-py
	test/localcomplete.sh $(SPARK_TEST_IMAGE) spark-complete
	SPARK_TEST_IMAGE=spark-complete test/run.sh completed/

test-e2e-py27:
	test/sparkinputs.sh
	LOCAL_IMAGE_PY27=$(SPARK_TEST_IMAGE_PY27) make -f Makefile.inc build-py27
	SPARK_TEST_IMAGE=$(SPARK_TEST_IMAGE_PY27) test/run.sh incomplete/

test-e2e-py27-completed:
	test/sparkinputs.sh
	LOCAL_IMAGE_PY27=$(SPARK_TEST_IMAGE_PY27) make -f Makefile.inc build-py27
	test/localcomplete.sh $(SPARK_TEST_IMAGE_PY27) spark-complete-py27
	SPARK_TEST_IMAGE=spark-complete-py27 test/run.sh completed/
