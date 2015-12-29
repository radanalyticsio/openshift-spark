REPO=mattf

.PHONY: build clean push create destroy

build:
	docker build -t openshift-spark .

clean:
	docker rmi openshift-spark

push: build
	docker tag -f openshift-spark $(REPO)/openshift-spark
	docker push $(REPO)/openshift-spark

create: push template.yaml
	oc process -f template.yaml -v SPARK_IMAGE=$(REPO)/openshift-spark > template.active
	oc create -f template.active

destroy: template.active
	oc delete -f template.active
	rm template.active
