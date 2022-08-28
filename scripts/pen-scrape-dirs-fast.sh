#!/bin/bash
export TTY

filter-partial-paths | print-line-if-path-exists | sort | uniq | dirs-only.sh
