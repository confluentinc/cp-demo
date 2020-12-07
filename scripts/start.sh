#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/helper/functions.sh
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

# Regenerate certificates and the Connect Docker image if any of the following conditions are true
if [[ "$CLEAN" == "true" ]] || \
 ! [[ -f "${DIR}/security/snakeoil-ca-1.crt" ]] || \
 ! [[ $(docker images --format "{{.Repository}}:{{.Tag}}" localbuild/connect:${CONFLUENT_DOCKER_TAG}-${CONNECTOR_VERSION}) =~ localbuild ]] ;
then
  if [[ -z $CLEAN ]] || [[ "$CLEAN" == "false" ]] ; then
    echo "INFO: Setting CLEAN=true because minimum conditions (existing certificates and existing Docker image localbuild/connect:${CONFLUENT_DOCKER_TAG}-${CONNECTOR_VERSION}) not met"
  fi
  CLEAN=true
  clean_demo_env
else
  CLEAN=false
fi

echo
echo "Environment parameters"
echo "  REPOSITORY=$REPOSITORY"
echo "  CONNECTOR_VERSION=$CONNECTOR_VERSION"
echo "  C3_KSQLDB_HTTPS=$C3_KSQLDB_HTTPS"
echo "  CLEAN=$CLEAN"
echo

#-------------------------------------------------------------------------------

# Do preflight checks
preflight_checks || exit

# Stop existing Docker containers
${DIR}/stop.sh

if [[ "$CLEAN" == "true" ]] ; then
  create_certificates
fi

# Bring up openldap
docker-compose up -d openldap
sleep 5
if [[ $(docker-compose ps openldap | grep Exit) =~ "Exit" ]] ; then
  echo "ERROR: openldap container could not start. Troubleshoot and try again. For troubleshooting instructions see https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html#troubleshooting"
  exit 1
fi

# Bring up base cluster and Confluent CLI
docker-compose up -d zookeeper kafka1 kafka2 tools

# Verify MDS has started
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for MDS to start"
retry $MAX_WAIT host_check_mds_up || exit 1
sleep 5

echo "Creating role bindings for principals"
docker-compose exec tools bash -c "/tmp/helper/create-role-bindings.sh" || exit 1

# Workaround for setting min ISR on topic _confluent-metadata-auth
docker-compose exec kafka1 kafka-configs \
   --bootstrap-server kafka1:12091 \
   --entity-type topics \
   --entity-name _confluent-metadata-auth \
   --alter \
   --add-config min.insync.replicas=1

# Build custom Kafka Connect image with required jars
if [[ "$CLEAN" == "true" ]] ; then
  build_connect_image || exit 1
fi

# Bring up more containers
docker-compose up -d schemaregistry connect control-center

echo
echo -e "Create topics in Kafka cluster:"
docker-compose exec kafka1 bash -c "/tmp/helper/create-topics.sh" || exit 1

# Verify Confluent Control Center has started
MAX_WAIT=300
echo "Waiting up to $MAX_WAIT seconds for Confluent Control Center to start"
retry $MAX_WAIT host_check_control_center_up || exit 1

echo -e "\n\nConfluent Control Center modifications:"
${DIR}/helper/control-center-modifications.sh
echo

# Verify Kafka Connect Worker has started
MAX_WAIT=240
echo -e "\nWaiting up to $MAX_WAIT seconds for Connect to start"
retry $MAX_WAIT host_check_connect_up || exit 1
sleep 2 # give connect an exta moment to fully mature

NUM_CERTS=$(docker-compose exec connect keytool --list --keystore /etc/kafka/secrets/kafka.connect.truststore.jks --storepass confluent | grep trusted | wc -l)
if [[ "$NUM_CERTS" -eq "1" ]]; then
  echo -e "\nERROR: Connect image did not build properly.  Expected ~147 trusted certificates but got $NUM_CERTS. Please troubleshoot and try again."
  exit 1
fi

echo
docker-compose up -d ksqldb-server ksqldb-cli restproxy kibana elasticsearch
echo "..."

# Verify Docker containers started
if [[ $(docker-compose ps) =~ "Exit 137" ]]; then
  echo -e "\nERROR: At least one Docker container did not start properly, see 'docker-compose ps'. Did you remember to increase the memory available to Docker to at least 8GB (default is 2GB)?\n"
  exit 1
fi

echo -e "\nStart streaming from the Wikipedia SSE source connector:"
${DIR}/connectors/submit_wikipedia_sse_config.sh

# Verify wikipedia.parsed topic is populated and schema is registered
MAX_WAIT=120
echo
echo -e "\nWaiting up to $MAX_WAIT seconds for subject wikipedia.parsed-value (for topic wikipedia.parsed) to be registered in Schema Registry"
retry $MAX_WAIT host_check_schema_registered || exit 1

# Verify ksqlDB server has started
MAX_WAIT=120
echo -e "\nWaiting up to $MAX_WAIT seconds for ksqlDB server to start"
retry $MAX_WAIT host_check_ksqlDBserver_up || exit 1
echo -e "\nRun ksqlDB queries (takes about 1 minute):"
${DIR}/ksqlDB/run_ksqlDB.sh

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
docker-compose up -d streams-demo
echo "..."

echo -e "\nStart Confluent Replicator:"
${DIR}/connectors/submit_replicator_config.sh

# Verify Elasticsearch is ready
MAX_WAIT=120
echo
echo -e "\nWaiting up to $MAX_WAIT seconds for Elasticsearch to be ready"
retry $MAX_WAIT host_check_elasticsearch_ready || exit 1
echo -e "\nProvide data mapping to Elasticsearch:"
${DIR}/dashboard/set_elasticsearch_mapping_bot.sh
${DIR}/dashboard/set_elasticsearch_mapping_count.sh
echo

echo -e "\nStart streaming to Elasticsearch sink connector:"
${DIR}/connectors/submit_elastic_sink_config.sh
echo

# Verify Kibana is ready
MAX_WAIT=120
echo
echo -e "\nWaiting up to $MAX_WAIT seconds for Kibana to be ready"
retry $MAX_WAIT host_check_kibana_ready || exit 1
echo -e "\nConfigure Kibana dashboard:"
${DIR}/dashboard/configure_kibana_dashboard.sh
echo

echo
echo -e "\nAvailable LDAP users:"
#docker-compose exec openldap ldapsearch -x -h localhost -b dc=confluentdemo,dc=io -D "cn=admin,dc=confluentdemo,dc=io" -w admin | grep uid:
curl -u mds:mds -X POST "https://localhost:8091/security/1.0/principals/User%3Amds/roles/UserAdmin" \
  -H "accept: application/json" -H "Content-Type: application/json" \
  -d "{\"clusters\":{\"kafka-cluster\":\"does_not_matter\"}}" \
  --cacert scripts/security/snakeoil-ca-1.crt --tlsv1.2
curl -u mds:mds -X POST "https://localhost:8091/security/1.0/rbac/principals" --silent \
  -H "accept: application/json"  -H "Content-Type: application/json" \
  -d "{\"clusters\":{\"kafka-cluster\":\"does_not_matter\"}}" \
  --cacert scripts/security/snakeoil-ca-1.crt --tlsv1.2 | jq '.[]'

echo -e "\n\n\n******************************************************************************************************************"
echo -e "DONE! Connect to Confluent Control Center at $C3URL (login as superUser/superUser for full access)"
echo -e "******************************************************************************************************************\n"
