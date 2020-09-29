#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../env_files/config.env

# REPOSITORY - repository (probably) for Docker images
# The '/' which separates the REPOSITORY from the image name is not required here
export REPOSITORY=${REPOSITORY:-confluentinc}

# If CONNECTOR_VERSION ~ `SNAPSHOT` then cp-demo uses Dockerfile-local
# and expects user to build and provide a local file confluentinc-kafka-connect-replicator-${CONNECTOR_VERSION}.zip
export CONNECTOR_VERSION=${CONNECTOR_VERSION:-$CONFLUENT}

docker-compose down --volumes

