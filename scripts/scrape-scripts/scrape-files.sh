#!/bin/bash
export TTY

path-candidates.sh | print-line-if-path-exists.sh | sort | uniq | files-only.sh