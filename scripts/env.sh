#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../env_files/config.env

#-------------------------------------------------------------------------------

# REPOSITORY - repository (probably) for Docker images
# The '/' which separates the REPOSITORY from the image name is not required here
export REPOSITORY=${REPOSITORY:-confluentinc}

# If CONNECTOR_VERSION ~ `SNAPSHOT` then cp-demo uses Dockerfile-local
# and expects user to build and provide a local file confluentinc-kafka-connect-replicator-${CONNECTOR_VERSION}.zip
export CONNECTOR_VERSION=${CONNECTOR_VERSION:-$CONFLUENT}

# Control Center and ksqlDB server must both be HTTP or both be HTTPS; mixed modes are not supported
# C3_KSQLDB_HTTPS=false: set Control Center and ksqlDB server to use HTTP (default)
# C3_KSQLDB_HTTPS=true : set Control Center and ksqlDB server to use HTTPS
export C3_KSQLDB_HTTPS=${C3_KSQLDB_HTTPS:-false}
if [[ "$C3_KSQLDB_HTTPS" == "false" ]]; then
  export CONTROL_CENTER_KSQL_WIKIPEDIA_URL="http://ksqldb-server:8088"
  export CONTROL_CENTER_KSQL_WIKIPEDIA_ADVERTISED_URL="http://localhost:8088"
  C3URL=http://localhost:9021
else
  export CONTROL_CENTER_KSQL_WIKIPEDIA_URL="https://ksqldb-server:8089"
  export CONTROL_CENTER_KSQL_WIKIPEDIA_ADVERTISED_URL="https://localhost:8089"
  C3URL=https://localhost:9022
fi

# Elasticsearch and Kibana increase memory requirements for cp-demo
# VIZ=true : run Elasticsearch and Kibana (default)
# VIZ=false: do not run Elasticsearch and Kibana
export VIZ=${VIZ:-true}

# Set consistent and strong cipher suites across all services
export SSL_CIPHER_SUITES=TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256,TLS_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256

# ZooKeeper image doesn't support TLS 1.3, so provide a couple of strong TLS 1.2 cipher suites
export ZOOKEEPER_SSL_CIPHER_SUITES=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
