#!/bin/bash

default:
	./scripts/run.sh

build-on-root-debian10:
	./scripts/setup.sh

run-docker:
	docker pull semiosis/pen.el:latest
	./scripts/run-pen-docker.sh

pull-docker:
	docker pull semiosis/pen.el:latest

push-docker:
	docker push semiosis/pen.el:latest