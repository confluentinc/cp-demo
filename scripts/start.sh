#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
. ${DIR}/helper/functions.sh
. ${DIR}/../env_files/config.env

DOCKER_COMPOSE_OPTS=${DOCKER_COMPOSE_OPTS:-""}

# Do preflight checks
preflight_checks || exit

# Stop existing demo Docker containers
${DIR}/stop.sh

# Generate keys and certificates used for SSL
echo -e "Generate keys and certificates used for SSL"
(cd ${DIR}/security && ./certs-create.sh)

# Generating public and private keys for token signing
echo "Generating public and private keys for token signing"
mkdir -p ./conf
openssl genrsa -out ./conf/keypair.pem 2048
openssl rsa -in ./conf/keypair.pem -outform PEM -pubout -out ./conf/public.pem

# Bring up openldap
docker-compose up -d openldap
sleep 5
if [[ $(docker-compose ps openldap | grep Exit) =~ "Exit" ]] ; then
  echo "ERROR: openldap container could not start. Troubleshoot and try again."
  exit 1
fi

# Bring up base cluster and Confluent CLI
docker-compose ${DOCKER_COMPOSE_OPTS} up -d zookeeper kafka1 kafka2 tools

# Verify Kafka brokers have started
MAX_WAIT=30
echo "Waiting up to $MAX_WAIT seconds for Kafka brokers to be registered in ZooKeeper"
retry $MAX_WAIT host_check_kafka_cluster_registered || exit 1

# Verify MDS has started
MAX_WAIT=60
echo "Waiting up to $MAX_WAIT seconds for MDS to start"
retry $MAX_WAIT host_check_mds_up || exit 1
sleep 5

echo "Creating role bindings for principals"
docker-compose exec tools bash -c "/tmp/helper/create-role-bindings.sh" || exit 1

echo

echo "Building custom Docker image with Connect version ${CONFLUENT_DOCKER_TAG} and connector version ${CONNECTOR_VERSION}"
if [[ "${CONNECTOR_VERSION}" =~ "SNAPSHOT" ]]; then
  echo "docker build --build-arg CP_VERSION=${CONFLUENT_DOCKER_TAG} --build-arg CONNECTOR_VERSION=${CONNECTOR_VERSION} -t localbuild/connect:${CONFLUENT_DOCKER_TAG}-${CONNECTOR_VERSION} -f Dockerfile-local ."
  docker build --build-arg CP_VERSION=${CONFLUENT_DOCKER_TAG} --build-arg CONNECTOR_VERSION=${CONNECTOR_VERSION} -t localbuild/connect:${CONFLUENT_DOCKER_TAG}-${CONNECTOR_VERSION} -f Dockerfile-local . || {
    echo "ERROR: Docker image build failed. Please troubleshoot and try again."
    exit 1;
  }
else
  echo "docker build --build-arg CP_VERSION=${CONFLUENT_DOCKER_TAG} --build-arg CONNECTOR_VERSION=${CONNECTOR_VERSION} -t localbuild/connect:${CONFLUENT_DOCKER_TAG}-${CONNECTOR_VERSION} -f Dockerfile-confluenthub ."
  docker build --build-arg CP_VERSION=${CONFLUENT_DOCKER_TAG} --build-arg CONNECTOR_VERSION=${CONNECTOR_VERSION} -t localbuild/connect:${CONFLUENT_DOCKER_TAG}-${CONNECTOR_VERSION} -f Dockerfile-confluenthub . || {
    echo "ERROR: Docker image build failed. Please troubleshoot and try again."
    exit 1;
  }
fi
docker-compose ${DOCKER_COMPOSE_OPTS} up -d kafka-client schemaregistry connect control-center

# Verify Confluent Control Center has started
MAX_WAIT=300
echo "Waiting up to $MAX_WAIT seconds for Confluent Control Center to start"
retry $MAX_WAIT host_check_control_center_up || exit 1

echo
docker-compose ${DOCKER_COMPOSE_OPTS} up -d ksqldb-server ksqldb-cli restproxy kibana elasticsearch
echo "..."

# Verify Docker containers started
if [[ $(docker-compose ps) =~ "Exit 137" ]]; then
  echo -e "\nERROR: At least one Docker container did not start properly, see 'docker-compose ps'. Did you remember to increase the memory available to Docker to at least 8GB (default is 2GB)?\n"
  exit 1
fi

# Verify Docker has the latest cp-kafka-connect image
if [[ $(docker-compose logs connect) =~ "server returned information about unknown correlation ID" ]]; then
  echo -e "\nERROR: Please update the cp-kafka-connect image with 'docker-compose pull'\n"
  exit 1
fi

# Verify Kafka Connect Worker has started
MAX_WAIT=240
echo "Waiting up to $MAX_WAIT seconds for Connect to start"
retry $MAX_WAIT host_check_connect_up || exit 1
sleep 2 # give connect an exta moment to fully mature

docker-compose exec connect timeout 3 nc -zv irc.wikimedia.org 6667 || {
  echo -e "\nERROR: irc.wikimedia.org 6667 is unreachable. Please ensure connectivity before proceeding or try setting 'irc.server.port' to 8001 in scripts/connectors/submit_wikipedia_irc_config.sh\n"
  exit 1
}

echo -e "\nStart streaming from the IRC source connector:"
${DIR}/connectors/submit_wikipedia_irc_config.sh

echo -e "\nProvide data mapping to Elasticsearch:"
${DIR}/dashboard/set_elasticsearch_mapping_bot.sh
${DIR}/dashboard/set_elasticsearch_mapping_count.sh
echo

echo -e "\nStart streaming to Elasticsearch sink connector:"
${DIR}/connectors/submit_elastic_sink_config.sh
echo

echo -e "\nConfigure Kibana dashboard:"
${DIR}/dashboard/configure_kibana_dashboard.sh
echo
echo

# Verify wikipedia.parsed topic is populated and schema is registered
MAX_WAIT=60
echo "Waiting up to $MAX_WAIT seconds for subject wikipedia.parsed-value (for topic wikipedia.parsed) to be registered in Schema Registry"
retry $MAX_WAIT host_check_schema_registered || exit 1

echo -e "\n\nRun ksqlDB queries:"
${DIR}/ksql/run_ksql.sh

echo -e "\nStart consumers for additional topics: WIKIPEDIANOBOT, EN_WIKIPEDIA_GT_1_COUNTS"
${DIR}/consumers/listen_WIKIPEDIANOBOT.sh
${DIR}/consumers/listen_EN_WIKIPEDIA_GT_1_COUNTS.sh

# Register the same schema for the replicated topic wikipedia.parsed.replica as was created for the original topic wikipedia.parsed
# In this case the replicated topic will register with the same schema ID as the original topic
echo -e "\nRegister subject wikipedia.parsed.replica-value in Schema Registry"
SCHEMA=$(docker-compose exec schemaregistry curl -s -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u superUser:superUser https://schemaregistry:8085/subjects/wikipedia.parsed-value/versions/latest | jq .schema)
docker-compose exec schemaregistry curl -X POST --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $SCHEMA}" -u superUser:superUser https://schemaregistry:8085/subjects/wikipedia.parsed.replica-value/versions

echo
echo "Start the Kafka Streams application wikipedia-activity-monitor"
docker-compose ${DOCKER_COMPOSE_OPTS} up -d streams-demo
echo "..."

echo -e "\nStart Confluent Replicator:"
${DIR}/connectors/submit_replicator_config.sh

echo -e "\n\nConfluent Control Center modifications:"
${DIR}/helper/control-center-modifications.sh

echo
echo -e "\nAvailable LDAP users:"
#docker-compose exec openldap ldapsearch -x -h localhost -b dc=confluentdemo,dc=io -D "cn=admin,dc=confluentdemo,dc=io" -w admin | grep uid:
curl -u mds:mds -X POST "http://localhost:8091/security/1.0/principals/User%3Amds/roles/UserAdmin" \
  -H "accept: application/json" -H "Content-Type: application/json" \
  -d "{\"clusters\":{\"kafka-cluster\":\"does_not_matter\"}}"
curl -u mds:mds -X POST "http://localhost:8091/security/1.0/rbac/principals" --silent \
  -H "accept: application/json"  -H "Content-Type: application/json" \
  -d "{\"clusters\":{\"kafka-cluster\":\"does_not_matter\"}}" | jq '.[]'

echo -e "\n\n\n*****************************************************************************************************************"
echo -e "DONE! Connect to Confluent Control Center at http://localhost:9021 (login as superUser/superUser for full access)"
echo -e "*****************************************************************************************************************\n"
