#!/bin/bash

docker exec schemaregistry ps aux | grep consumer_app | grep -v "grep" | awk '{print $2}' | xargs docker exec schemaregistry kill -9
ps aux | grep "docker exec schemaregistry" | grep -v "grep" | awk '{print $2}' | xargs kill -9
