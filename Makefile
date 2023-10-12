IMAGE=europe-west9-docker.pkg.dev/workshop-dev-347207/repo-workstations/jupyter-notebook:v2


all: build push

build:
	docker build . -t ${IMAGE}

push:
	docker push ${IMAGE}
