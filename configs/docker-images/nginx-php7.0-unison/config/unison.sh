#!/usr/bin/env bash

# Run in foreground to warmup
su - www-data -c "unison public_html"

# Run unison server
su - www-data -c "unison -repeat=watch public_html > /home/www-data/custom_unison.log 2>&1 &"