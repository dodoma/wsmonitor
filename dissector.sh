#!/bin/bash

# http, websocket 通信刨析器，可用来观察 与目标机 指定端口 的指定方向的通信内容

# TODO
# 1. 可能需要对拆分后的包进行组包

useage()
{
    echo "useage: $0 direction host port"
    echo "example: $0 src pdk.pkgame.net 8500"
    echo "direction: src, dst, or all."
    exit -1
}

if [ $# -lt 3 ]; then
    useage
fi

DIRECTION=$1
HOST=$2
PORT=$3
#if [ -n "$3" ]; then DIRECTION=$3; else DIRECTION="all"; fi
if [ "$DIRECTION" != "src" ] && [ "$DIRECTION" != "dst" ]; then DIRECTION=""; fi

sudo tcpdump -s 0 -l -w - $DIRECTION host $HOST and port $PORT | tcpflow -c -D -r - | awk -F'[0-9a-e]{4}: ' '{if ($0 ~ /192.168/) { if ($0 ~ /^192.168/) {print "__RSV0__";} else {print "__RSV1__";}} print $2; fflush()}' | awk -F' [ .]' '{print $1; fflush()}' | sed -u 's/ //g' | ./combine_lines.sh
