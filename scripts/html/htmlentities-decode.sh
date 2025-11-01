#!/bin/bash
export TTY

perl -MHTML::Entities -pe 'decode_entities($_);' 2>/dev/null