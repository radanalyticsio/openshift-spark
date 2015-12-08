REPO=mattf

.PHONY: build
build: build-master build-worker
clean: clean-base clean-master clean-worker
push: push-master push-worker
resources: expand-master-template expand-worker-template expand-app-template

build-base:
	docker build -t openshift-spark-base base

build-master: build-base
	docker build -t openshift-spark-master master

build-worker: build-base
	docker build -t openshift-spark-worker worker

clean-base:
	docker rmi openshift-spark-base

clean-master:
	docker rmi openshift-spark-master

clean-worker:
	docker rmi openshift-spark-worker

push-master: build-master
	docker tag -f openshift-spark-master $(REPO)/openshift-spark-master
	docker push $(REPO)/openshift-spark-master

push-worker: build-worker
	docker tag -f openshift-spark-worker $(REPO)/openshift-spark-worker
	docker push $(REPO)/openshift-spark-worker

expand-master-template:
	REPO=${REPO} envsubst <resources/spark-master-controller.yaml.template >resources/spark-master-controller.yaml

expand-worker-template:
	REPO=${REPO} envsubst <resources/spark-worker-controller.yaml.template >resources/spark-worker-controller.yaml

expand-app-template:
	sed "s,_REPO_,$(REPO)," resources/template.yaml.template >resources/template.yaml

create: build push resources
	oc create -f resources/spark-master-service.yaml
	oc create -f resources/spark-master-webui-service.yaml
	oc create -f resources/spark-master-controller.yaml
	oc create -f resources/spark-worker-controller.yaml

destroy:
	oc delete -f resources/spark-master-service.yaml
	oc delete -f resources/spark-master-webui-service.yaml
	oc delete -f resources/spark-master-controller.yaml
	oc delete -f resources/spark-worker-controller.yaml
