#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/helper/functions.sh
source ${DIR}/../env_files/config.env

# Do preflight checks
preflight_checks || exit

# Stop existing demo Docker containers
${DIR}/stop.sh

# Generate keys and certificates used for SSL
echo -e "Generate keys and certificates used for SSL"
(cd ${DIR}/security && ./certs-create.sh)

# Generating public and private keys for token signing
echo "Generating public and private keys for token signing"
mkdir -p ${DIR}/security/keypair
openssl genrsa -out ${DIR}/security/keypair/keypair.pem 2048
openssl rsa -in ${DIR}/security/keypair/keypair.pem -outform PEM -pubout -out ${DIR}/security/keypair/public.pem

# Bring up openldap
docker-compose up -d openldap
sleep 5
if [[ $(docker-compose ps openldap | grep Exit) =~ "Exit" ]] ; then
  echo "ERROR: openldap container could not start. Troubleshoot and try again."
  exit 1
fi

# Bring up base cluster and Confluent CLI
docker-compose up -d zookeeper kafka1 kafka2 tools

# Verify MDS has started
MAX_WAIT=90
echo "Waiting up to $MAX_WAIT seconds for MDS to start"
retry $MAX_WAIT host_check_mds_up || exit 1
sleep 5

echo "Creating role bindings for principals"
docker-compose exec tools bash -c "/tmp/helper/create-role-bindings.sh" || exit 1

docker-compose up -d kafka-client schemaregistry
