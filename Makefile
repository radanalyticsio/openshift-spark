LOCAL_IMAGE ?= openshift-spark
SPARK_IMAGE=radanalyticsio/openshift-spark
DOCKERFILE_CONTEXT=openshift-spark-build

# If you're pushing to an integrated registry
# in Openshift, SPARK_IMAGE will look something like this

# SPARK_IMAGE=172.30.242.71:5000/myproject/openshift-spark

OPENSHIFT_SPARK_TEST_IMAGE ?= spark-testimage
export OPENSHIFT_SPARK_TEST_IMAGE

.PHONY: build clean push create destroy test-e2e test-e2e-py test-e2e-py27 build-py build-py27 clean-target clean-context zero-tarballs

build: build-py build-py27

build-py: $(DOCKERFILE_CONTEXT)
	podman build -t $(LOCAL_IMAGE) $(DOCKERFILE_CONTEXT)

build-py27: $(DOCKERFILE_CONTEXT)-py27
	podman build -t $(LOCAL_IMAGE)-py27 $(DOCKERFILE_CONTEXT)-py27

clean: clean-target clean-context
	-podman rmi $(LOCAL_IMAGE)
	-podman rmi $(LOCAL_IMAGE)-py27

push: build
	podman tag $(LOCAL_IMAGE) $(SPARK_IMAGE)
	podman push $(SPARK_IMAGE)
	podman tag $(LOCAL_IMAGE)-py27 $(SPARK_IMAGE)-py27
	podman push $(SPARK_IMAGE)-py27

create: push template.yaml
	oc process -f template.yaml -v SPARK_IMAGE=$(SPARK_IMAGE) > template.active
	oc create -f template.active
	oc process -f template.yaml -v SPARK_IMAGE=$(SPARK_IMAGE)-py27 > template-py27.active
	oc create -f template-py27.active

destroy: template.active
	oc delete -f template.active
	rm template.active
	oc delete -f template-py27.active
	rm template-py27.active

clean-context:
	-rm -rf $(DOCKERFILE_CONTEXT)/*
	-rm -rf $(DOCKERFILE_CONTEXT)-py27/*

clean-target:
	-rm -rf target
	-rm -rf target-py27

context: $(DOCKERFILE_CONTEXT) $(DOCKERFILE_CONTEXT)-py27

$(DOCKERFILE_CONTEXT): $(DOCKERFILE_CONTEXT)/Dockerfile \
	                   $(DOCKERFILE_CONTEXT)/modules

$(DOCKERFILE_CONTEXT)-py27: $(DOCKERFILE_CONTEXT)-py27/Dockerfile \
							$(DOCKERFILE_CONTEXT)-py27/modules

$(DOCKERFILE_CONTEXT)/Dockerfile $(DOCKERFILE_CONTEXT)/modules:
	cekit --descriptor image.yaml build --overrides overrides/default.yaml --dry-run podman
	cp -R target/image/* $(DOCKERFILE_CONTEXT)

$(DOCKERFILE_CONTEXT)-py27/Dockerfile $(DOCKERFILE_CONTEXT)-py27/modules:
	cekit --descriptor image.yaml --target target-py27 build --overrides overrides/python27.yaml --dry-run podman
	cp -R target-py27/image/* $(DOCKERFILE_CONTEXT)-py27

zero-tarballs:
	find ./$(DOCKERFILE_CONTEXT) -name "*.tgz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT) -name "*.tar.gz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT)-py27 -name "*.tgz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT)-py27 -name "*.tar.gz" -type f -exec truncate -s 0 {} \;

test-e2e:
	LOCAL_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE) make build
	test/run.sh completed/
	SPARK_TEST_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE)-py27 test/run.sh completed/

test-e2e-py:
	LOCAL_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE) make build-py
	test/run.sh completed/

test-e2e-py27:
	LOCAL_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE) make build-py27
	SPARK_TEST_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE)-py27 test/run.sh completed/
