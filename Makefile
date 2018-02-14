LOCAL_IMAGE=openshift-spark
SPARK_IMAGE=mattf/openshift-spark
DOCKERFILE_CONTEXT=openshift-spark-build

# If you're pushing to an integrated registry
# in Openshift, SPARK_IMAGE will look something like this
# SPARK_IMAGE=172.30.242.71:5000/myproject/openshift-spark

OPENSHIFT_SPARK_TEST_IMAGE ?= spark-testimage
export OPENSHIFT_SPARK_TEST_IMAGE

.PHONY: build clean push create destroy

build: $(DOCKERFILE_CONTEXT)
	docker build -t $(LOCAL_IMAGE) $(DOCKERFILE_CONTEXT)

clean:
	docker rmi $(LOCAL_IMAGE)

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
	-rm -f $(DOCKERFILE_CONTEXT)/Dockerfile
	-rm -rf $(DOCKERFILE_CONTEXT)/modules
	-rm -rf $(DOCKERFILE_CONTEXT)/*.tgz

context: clean-context
	concreate generate --descriptor=image.yaml
	cp -R target/image/* $(DOCKERFILE_CONTEXT)
	$(MAKE) zero-tarballs

zero-tarballs:
	-truncate -s 0 $(DOCKERFILE_CONTEXT)/*.tgz

test-e2e:
	LOCAL_IMAGE=$(OPENSHIFT_SPARK_TEST_IMAGE) make build
	test/run.sh
