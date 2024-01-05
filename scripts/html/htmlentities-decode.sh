#!/bin/bash
export TTY

perl -MHTML::Entities -pe 'decode_entities($_);'