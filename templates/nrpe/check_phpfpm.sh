#!/bin/bash

change=`ps ax | grep fpm | grep master`
if [ $? -eq 0 ]; then
    echo "Ok - php-fpm is present"
    exit 0
else
    echo "php-fpm is NOT present"
    exit 1
fi

