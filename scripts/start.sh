#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source ${DIR}/functions.sh

#set -o nounset \
#    -o errexit \
#    -o verbose

verify_installed "jq"
verify_installed "docker-compose"
verify_installed "keytool"
verify_installed "docker"
verify_installed "openssl"

# Verify Docker memory is increased to at least 8GB
DOCKER_MEMORY=$(docker system info | grep Memory | grep -o "[0-9\.]\+")
if (( $(echo "$DOCKER_MEMORY 7.0" | awk '{print ($1 < $2)}') )); then
  echo -e "\nWARNING: Did you remember to increase the memory available to Docker to at least 8GB (default is 2GB)? Demo may otherwise not work properly.\n"
  sleep 3
fi

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

# Bring up Docker Compose
echo -e "Starting Zookeeper, Kafka1, LDAP server"
docker-compose up -d kafka1

# wait for kafka container to be healthy
echo
echo "Waiting for kafka1 to be healthy"
retry 30 5 container_healthy kafka1

# start the rest of the cluster
echo
echo "Starting the rest of the services"
docker-compose up -d
echo "..."

# Set role bindings
echo
echo "Creating role bindings for service accounts"
docker-compose exec tools bash -c "/tmp/create-role-bindings.sh"

# Verify Confluent Control Center has started within MAX_WAIT seconds
MAX_WAIT=300
CUR_WAIT=0
echo "Waiting up to $MAX_WAIT seconds for Confluent Control Center to start"
while [[ ! $(docker-compose logs control-center) =~ "Started NetworkTrafficServerConnector" ]]; do
  sleep 3
  CUR_WAIT=$(( CUR_WAIT+3 ))
  if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
    echo -e "\nERROR: The logs in control-center container do not show 'Started NetworkTrafficServerConnector' after $MAX_WAIT seconds. Please troubleshoot with 'docker-compose ps' and 'docker-compose logs'.\n"
    exit 1
  fi
done

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

# Verify Kafka Connect Worker has started within 120 seconds
MAX_WAIT=120
CUR_WAIT=0
echo "Waiting up to $MAX_WAIT seconds for Kafka Connect Worker to start"
while [[ ! $(docker-compose logs connect) =~ "Herder started" ]]; do
  sleep 3
  CUR_WAIT=$(( CUR_WAIT+3 ))
  if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
    echo -e "\nERROR: The logs in Kafka Connect container do not show 'Herder started'. Please troubleshoot with 'docker-compose ps' and 'docker-compose logs'.\n"
    exit 1
  fi
done

docker-compose exec connect timeout 3 nc -zv irc.wikimedia.org 6667 || {
  echo -e "\nERROR: irc.wikimedia.org 6667 is unreachable. Please ensure connectivity before proceeding or try setting 'irc.server.port' to 8001 in scripts/connectors/submit_wikipedia_irc_config.sh\n"
  exit 1
}

echo -e "\nStart streaming from the IRC source connector:"
${DIR}/connectors/submit_wikipedia_irc_config.sh

echo -e "\nProvide data mapping to Elasticsearch:"
${DIR}/dashboard/set_elasticsearch_mapping_bot.sh
${DIR}/dashboard/set_elasticsearch_mapping_count.sh

echo -e "\nStart streaming to Elasticsearch sink connector:"
${DIR}/connectors/submit_elastic_sink_config.sh

echo -e "\nConfigure Kibana dashboard:"
${DIR}/dashboard/configure_kibana_dashboard.sh

echo -e "\n\nRun KSQL queries:"
${DIR}/ksql/run_ksql.sh

echo -e "\nStart consumers for additional topics: WIKIPEDIANOBOT, EN_WIKIPEDIA_GT_1_COUNTS"
${DIR}/consumers/listen_WIKIPEDIANOBOT.sh
${DIR}/consumers/listen_EN_WIKIPEDIA_GT_1_COUNTS.sh

# Verify wikipedia.parsed topic is populated and schema is registered
MAX_WAIT=50
CUR_WAIT=0
echo -e "\nWaiting up to $MAX_WAIT seconds for wikipedia.parsed topic to be populated"
while [[ ! $(docker-compose exec schemaregistry curl -s -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u professor:professor https://schemaregistry:8085/subjects) =~ "wikipedia.parsed-value" ]]; do
  sleep 3
  CUR_WAIT=$(( CUR_WAIT+3 ))
  if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
    echo -e "\nERROR: IRC connector is not populating the Kafka topic wikipedia.parsed. Please troubleshoot with 'docker-compose ps' and 'docker-compose logs'.\n"
    exit 1
  fi
done

# Register the same schema for the replicated topic wikipedia.parsed.replica as was created for the original topic wikipedia.parsed
# In this case the replicated topic will register with the same schema ID as the original topic
SCHEMA=$(docker-compose exec schemaregistry curl -s -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u professor:professor https://schemaregistry:8085/subjects/wikipedia.parsed-value/versions/latest | jq .schema)
docker-compose exec schemaregistry curl -X POST --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $SCHEMA}" -u professor:professor https://schemaregistry:8085/subjects/wikipedia.parsed.replica-value/versions

echo -e "\nStart Confluent Replicator:"
${DIR}/connectors/submit_replicator_config.sh

echo -e "\Confluent Control Center modifications:"
${DIR}/control-center-modifications.sh


echo -e "\n\n\n******************************************************************"
echo -e "DONE! Connect to Confluent Control Center at http://localhost:9021 (login as professor/professor for full access)"
echo -e "******************************************************************\n"
