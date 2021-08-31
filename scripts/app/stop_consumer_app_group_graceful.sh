#!/bin/bash

docker exec connect ps aux | grep consumer_app | grep -v "grep" | awk '{print $2}' | xargs docker exec connect kill -15
ps aux | grep "docker exec connect" | grep -v "grep" | awk '{print $2}' | xargs kill -15
