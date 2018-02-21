LOCAL_IMAGE ?= openshift-spark
SPARK_IMAGE=mattf/openshift-spark
DOCKERFILE_CONTEXT=openshift-spark-build

# If you're pushing to an integrated registry
# in Openshift, SPARK_IMAGE will look something like this

# SPARK_IMAGE=172.30.242.71:5000/myproject/openshift-spark

OPENSHIFT_SPARK_TEST_IMAGE ?= spark-testimage
export OPENSHIFT_SPARK_TEST_IMAGE

.PHONY: build clean push create destroy test-e2e

build: $(DOCKERFILE_CONTEXT)
	docker build -t $(LOCAL_IMAGE) $(DOCKERFILE_CONTEXT)

clean: clean-context
	-docker rmi $(LOCAL_IMAGE)

push: build
	docker tag $(LOCAL_IMAGE) $(SPARK_IMAGE)
	docker push $(SPARK_IMAGE)

create: push template.yaml
	oc process -f template.yaml -v SPARK_IMAGE=$(SPARK_IMAGE) > template.active
	oc create -f template.active

destroy: template.active
	oc delete -f template.active
	rm template.active

clean-context:
	-rm -rf target
	-rm -rf $(DOCKERFILE_CONTEXT)/*

context: $(DOCKERFILE_CONTEXT)

$(DOCKERFILE_CONTEXT): $(DOCKERFILE_CONTEXT)/Dockerfile $(DOCKERFILE_CONTEXT)/modules

$(DOCKERFILE_CONTEXT)/Dockerfile $(DOCKERFILE_CONTEXT)/modules:
	concreate generate --descriptor image.yaml
	cp -R target/image/* $(DOCKERFILE_CONTEXT)

zero-tarballs:
	find ./$(DOCKERFILE_CONTEXT) -name "*.tgz" -type f -exec truncate -s 0 {} \;
	find ./$(DOCKERFILE_CONTEXT) -name "*.tar.gz" -type f -exec truncate -s 0 {} \;

test-e2e:
	LOCAL_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE) make build
	test/run.sh
