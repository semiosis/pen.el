#!/bin/bash
export TTY

# https://unix.stackexchange.com/questions/383164/how-to-transpose-a-text-file-on-character-basis

# The awk solution is the most reliable

# fill-lines-to-longest-line | transpose-chars-awk.sh | pavs

# TODO Make it so this exchanges spaces ' ' before and after translation

sed 's/ /✓/g' | transpose-chars-awk.sh | erase-trailing-whitespace | sed 's/✓/ /g' | pavs

# ub sps v "$input_fp"

# sed -e 's/./& /g' -e 's/ $//' | rs -Tng0