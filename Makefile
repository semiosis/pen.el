#!/bin/bash

default:
	./src/run.sh

build-on-root-debian10:
	./src/setup.sh

pull-docker:
	docker pull semiosis/pen.el:latest

push-docker:
	docker push semiosis/pen.el:latest