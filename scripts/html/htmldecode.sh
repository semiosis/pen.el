#!/bin/bash

perl -C -MHTML::Entities -pe 'decode_entities($_);'