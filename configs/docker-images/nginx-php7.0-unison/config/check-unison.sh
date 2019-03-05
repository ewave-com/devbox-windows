#!/usr/bin/env bash

while [ 1 == 1 ]; do
    ps aux | grep "[u]nison -repeat=watch public_html"
    if [ $? != 0 ]
    then
        (su - www-data -c 'unison -repeat=watch public_html') &
    fi
    sleep 10
done