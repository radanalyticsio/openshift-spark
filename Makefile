REPO=mattf

.PHONY: build clean push create destroy

build:
	docker build -t openshift-spark-base base

clean:
	docker rmi openshift-spark-base

push: build
	docker tag -f openshift-spark-base $(REPO)/openshift-spark-base
	docker push $(REPO)/openshift-spark-base

create: push
	sed "s,_REPO_,$(REPO)," resources/template.yaml.template >resources/template.yaml
	oc process -f resources/template.yaml > resources/template.active
	oc create -f resources/template.active

destroy:
	oc delete -f resources/template.active
