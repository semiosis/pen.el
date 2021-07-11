#!/bin/bash

docker run --rm -v "$(pwd):/$(pwd | slugify)" -w "/root" -ti --entrypoint= semiosis:pen.el bash 