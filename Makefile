LOCAL_IMAGE ?= openshift-spark
SPARK_IMAGE=radanalyticsio/openshift-spark
DOCKERFILE_CONTEXT=openshift-spark-build

# If you're pushing to an integrated registry
# in Openshift, SPARK_IMAGE will look something like this

# SPARK_IMAGE=172.30.242.71:5000/myproject/openshift-spark

OPENSHIFT_SPARK_TEST_IMAGE ?= spark-testimage
export OPENSHIFT_SPARK_TEST_IMAGE

.PHONY: build clean push create destroy test-e2e test-e2e-py test-e2e-py36 build-py build-py36 clean-target clean-context zero-tarballs

build: build-py build-py36

build-py: $(DOCKERFILE_CONTEXT)
	docker build -t $(LOCAL_IMAGE) $(DOCKERFILE_CONTEXT)

build-py36: $(DOCKERFILE_CONTEXT)-py36
	docker build -t $(LOCAL_IMAGE)-py36 $(DOCKERFILE_CONTEXT)-py36

clean: clean-context
	-docker rmi $(LOCAL_IMAGE)
	-docker rmi $(LOCAL_IMAGE)-py36

push: build
	docker tag $(LOCAL_IMAGE) $(SPARK_IMAGE)
	docker push $(SPARK_IMAGE)
	docker tag $(LOCAL_IMAGE)-py36 $(SPARK_IMAGE)-py36
	docker push $(SPARK_IMAGE)-py36

create: push template.yaml
	oc process -f template.yaml -v SPARK_IMAGE=$(SPARK_IMAGE) > template.active
	oc create -f template.active
	oc process -f template.yaml -v SPARK_IMAGE=$(SPARK_IMAGE)-py36 > template-py36.active
	oc create -f template-py36.active

destroy: template.active
	oc delete -f template.active
	rm template.active
	oc delete -f template-py36.active
	rm template-py36.active

clean-context:
	-rm -rf $(DOCKERFILE_CONTEXT)/*
	-rm -rf $(DOCKERFILE_CONTEXT)-py36/*

clean-target:
	-rm -rf target
	-rm -rf target-py36

context: $(DOCKERFILE_CONTEXT) $(DOCKERFILE_CONTEXT)-py36

$(DOCKERFILE_CONTEXT): $(DOCKERFILE_CONTEXT)/Dockerfile \
	                   $(DOCKERFILE_CONTEXT)/modules

$(DOCKERFILE_CONTEXT)-py36: $(DOCKERFILE_CONTEXT)-py36/Dockerfile \
							$(DOCKERFILE_CONTEXT)-py36/modules

$(DOCKERFILE_CONTEXT)/Dockerfile $(DOCKERFILE_CONTEXT)/modules:
	cekit generate --descriptor image.yaml --overrides overrides/default.yaml
	cp -R target/image/* $(DOCKERFILE_CONTEXT)

$(DOCKERFILE_CONTEXT)-py36/Dockerfile $(DOCKERFILE_CONTEXT)-py36/modules:
	cekit generate --descriptor image.yaml --overrides overrides/python36.yaml --target target-py36
	cp -R target-py36/image/* $(DOCKERFILE_CONTEXT)-py36

zero-tarballs:
	find ./$(DOCKERFILE_CONTEXT) -name "*.tgz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT) -name "*.tar.gz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT)-py36 -name "*.tgz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT)-py36 -name "*.tar.gz" -type f -exec truncate -s 0 {} \;

test-e2e:
	LOCAL_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE) make build
	test/run.sh completed/
	SPARK_TEST_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE)-py36 test/run.sh completed/

test-e2e-py:
	LOCAL_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE) make build-py
	test/run.sh completed/

test-e2e-py36:
	LOCAL_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE) make build-py36
	SPARK_TEST_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE)-py36 test/run.sh completed/
