#!/bin/bash

docker run --rm -v "$(pwd):/$(pwd | scripts/slugify)" -ti --entrypoint= semiosis/pen.el:latest ./run.sh