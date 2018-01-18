#!/bin/bash

ps aux | grep ksql-server-start | grep -v "grep ksql" | awk '{print $2}' | xargs kill -15

docker-compose down
docker volume ls -q --filter dangling=true | xargs docker volume rm
