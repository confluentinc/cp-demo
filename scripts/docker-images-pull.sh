#!/bin/bash
  
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/env.sh


maybe_pull_docker_image() {
  FULL_NAME=$1

  if [[ $(docker images -q $FULL_NAME) == "" ]]; then
    echo "$FULL_NAME does not exist"
    echo "docker image pull $FULL_NAME"
    docker image pull $FULL_NAME || return 1
  else
    echo "$FULL_NAME already exists"
  fi

  return 0
}

echo
echo "Downloading Docker images"

# Confluent Platform images
declare -a NAMES=("cp-zookeeper" \
                  "cp-server" \
                  "cp-enterprise-control-center" \
                  "cp-schema-registry" \
                  "cp-ksqldb-server" \
                  "cp-ksqldb-cli" \
                  "cp-kafka-rest")
for NAME in "${NAMES[@]}"; do
  FULL_NAME="${REPOSITORY}/${NAME}:${CONFLUENT_DOCKER_TAG}"
  maybe_pull_docker_image $FULL_NAME || exit 1
done

# Other Docker images used in cp-demo
declare -a FULL_NAMES=("cnfltraining/training-tools:6.0" \
                  "osixia/openldap:1.3.0" \
                  "docker.elastic.co/elasticsearch/elasticsearch-oss:7.10.0" \
                  "docker.elastic.co/kibana/kibana-oss:7.10.0" \
                  "cnfldemos/cp-demo-kstreams:0.0.9")
for FULL_NAME in "${FULL_NAMES[@]}"; do
  maybe_pull_docker_image $FULL_NAME || exit 1
done
