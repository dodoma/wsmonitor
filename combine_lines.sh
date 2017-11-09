#!/bin/bash

param=''

while [ True ]; do

    read line

    if [ ${#line} != 0 ]; then
        param+=$line
    else
        echo $param
        param=''
    fi

done
