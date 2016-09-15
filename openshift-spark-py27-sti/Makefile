BASE_IMAGE=centos/python-27-centos7:latest
LOCAL_IMAGE=openshift-spark-py27-sti
SPARK_IMAGE=myproject/openshift-spark-py27-sti

.PHONY: build clean push create destroy artifacts clean-artifacts clean-dockerfile clean-scripts clean-template

build:
	docker build -t $(LOCAL_IMAGE) .

clean:
	- docker rmi $(LOCAL_IMAGE)

push: build
	docker tag -f $(LOCAL_IMAGE) $(SPARK_IMAGE)
	docker push $(SPARK_IMAGE)

create: template.yaml
	oc process -f template.yaml -v SPARK_IMAGE=$(SPARK_IMAGE) > template.active
	oc create -f template.active

destroy: template.active
	oc delete -f template.active
	rm template.active

artifacts: Dockerfile scripts template.yaml

Dockerfile:
	cp ../Dockerfile .
	sed -i '/FROM/c \FROM ${BASE_IMAGE}' Dockerfile

scripts:
	cp -r ../scripts .

template.yaml:
	cp ../template.yaml .

clean-artifacts: clean-dockerfile clean-scripts clean-template

clean-dockerfile: Dockerfile
	rm Dockerfile

clean-scripts: scripts
	rm -r scripts

clean-template: template.yaml
	rm template.yaml
