IMAGE=IMAGE_NAME


all: build push

build:
	docker build . -t ${IMAGE}

push:
	docker push ${IMAGE}
