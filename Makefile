#!/bin/bash

default:
	./src/run.sh

build-on-root-debian10:
	./src/setup.sh

push-docker:
	docker push semiosis/pen.el:latest