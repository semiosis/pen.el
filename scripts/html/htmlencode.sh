#!/bin/bash

# encode_entities usually only encode unsafe entities
# I also specify ()
perl -C -MHTML::Entities -pe "encode_entities(\$_, '()');" | sed -z "s=\n=<br />=g"
