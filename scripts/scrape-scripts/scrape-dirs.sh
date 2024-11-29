#!/bin/bash
export TTY

path-candidates.sh | print-line-if-path-exists.sh | sort | uniq | dirs-only.sh
