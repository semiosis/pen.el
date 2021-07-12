#!/bin/bash

default:
	./src/run.sh

build-on-root-debian10:
	./src/setup.sh

run-docker
	docker pull semiosis/pen.el:latest
	docker run --rm -v "$(pwd):/$(pwd | slugify)" -ti --entrypoint= semiosis/pen.el:latest ./run.sh

pull-docker:
	docker pull semiosis/pen.el:latest

push-docker:
	docker push semiosis/pen.el:latest