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

# Set consistent and strong cipher suites across all services
export SSL_CIPHER_SUITES=TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256,TLS_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256

# ZooKeeper image doesn't support TLS 1.3, so provide a couple of strong TLS 1.2 cipher suites
export ZOOKEEPER_SSL_CIPHER_SUITES=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
