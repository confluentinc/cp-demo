#!/bin/bash

DOCKER_COMPOSE_OPTS=${DOCKER_COMPOSE_OPTS:-""}
docker-compose $DOCKER_COMPOSE_OPTS down --volumes

