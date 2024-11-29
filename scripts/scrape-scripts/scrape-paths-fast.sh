#!/bin/bash
export TTY

filter-partial-paths.sh | print-line-if-path-exists.sh | sort | uniq
