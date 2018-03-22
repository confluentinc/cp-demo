#!/bin/bash

ps aux | grep ksql-server-start | grep -v "grep ksql" | awk '{print $2}' | xargs kill -15

docker-compose down

for v in $(docker volume ls -q --filter="dangling=true"); do
	docker volume rm "$v"
done
