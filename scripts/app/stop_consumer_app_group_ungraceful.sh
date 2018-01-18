#!/bin/bash

docker exec cpdemo_connect_1 ps aux | grep consumer_app | grep -v "grep" | awk '{print $2}' | xargs docker exec cpdemo_connect_1 kill -9
ps aux | grep "docker exec cpdemo_connect_1" | grep -v "grep" | awk '{print $2}' | xargs kill -9
