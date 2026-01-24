#!/bin/bash
export TTY

filter-partial-paths | print-line-if-path-exists | uniqnosort  | files-only.sh
