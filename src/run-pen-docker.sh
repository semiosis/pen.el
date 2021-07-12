#!/bin/bash

docker run --rm -v "$(shell pwd):/$(shell pwd | scripts/slugify)" -ti --entrypoint= semiosis/pen.el:latest ./run.sh