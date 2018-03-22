#!/bin/bash

ps aux | grep ksql-server-start | grep -v "grep ksql" | awk '{print $2}' | xargs kill -15

docker-compose down

volumes=$(docker volume ls -q --filter="dangling=true")
if [ -n "$volumes" ]; then
	docker volumes rm "$volumes"
fi