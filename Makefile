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
	sed "s,_REPO_,$(REPO)," template.yaml.template > template.yaml
	oc process -f template.yaml > template.active
	oc create -f template.active

destroy:
	oc delete -f template.active
