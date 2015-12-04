REPO=mattf/

.PHONY: build
build: build-base build-master build-worker
clean: clean-base clean-master clean-worker

build-base:
	docker build -t $(REPO)openshift-spark-base base

build-master:
	docker build -t $(REPO)openshift-spark-master master

build-worker:
	docker build -t $(REPO)openshift-spark-worker worker

clean-base:
	docker rmi $(REPO)openshift-spark-base

clean-master:
	docker rmi $(REPO)openshift-spark-master

clean-worker:
	docker rmi $(REPO)openshift-spark-master
