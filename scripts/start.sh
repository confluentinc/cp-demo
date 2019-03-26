#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#set -o nounset \
#    -o errexit \
#    -o verbose

verify_installed()
{
  local cmd="$1"
  if [[ $(type $cmd 2>&1) =~ "not found" ]]; then
    echo -e "\nERROR: This script requires '$cmd'. Please install '$cmd' and run again.\n"
    exit 1
  fi
}
verify_installed "jq"
verify_installed "docker-compose"

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

# Bring up Docker Compose
echo -e "Bringing up Docker Compose"
docker-compose up -d

# Verify Confluent Control Center has started within MAX_WAIT seconds
MAX_WAIT=300
CUR_WAIT=0
echo "Waiting up to $MAX_WAIT seconds for Confluent Control Center to start"
while [[ ! $(docker-compose logs control-center) =~ "Started NetworkTrafficServerConnector" ]]; do
  sleep 10
  CUR_WAIT=$(( CUR_WAIT+10 ))
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

echo -e "\nRename the cluster in Control Center:"
# If you have 'jq'
curl -X PATCH  -H "Content-Type: application/merge-patch+json" -d '{"displayName":"Kafka Raleigh"}' http://localhost:9021/2.0/clusters/kafka/$(curl -X GET http://localhost:9021/2.0/clusters/kafka/ | jq --raw-output '.[0].clusterId')
# If you don't have 'jq'
#curl -X PATCH  -H "Content-Type: application/merge-patch+json" -d '{"displayName":"Kafka Raleigh"}' http://localhost:9021/2.0/clusters/kafka/$(curl -X GET http://localhost:9021/2.0/clusters/kafka/ | awk -v FS="(clusterId\":\"|\",\"displayName)" '{print $2}' )

# Verify Kafka Connect Worker has started within 60 seconds
MAX_WAIT=60
CUR_WAIT=0
while [[ ! $(docker-compose logs connect) =~ "Herder started" ]]; do
  sleep 10
  CUR_WAIT=$(( CUR_WAIT+10 ))
  if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
    echo -e "\nERROR: The logs in Kafka Connect container do not show 'Herder started'. Please troubleshoot with 'docker-compose ps' and 'docker-compose logs'.\n"
    exit 1
  fi
done

if [[ ! $(docker-compose exec connect timeout 3 nc -zv irc.wikimedia.org 6667) =~ "open" ]]; then
  echo -e "\nERROR: irc.wikimedia.org 6667 is unreachable. Please ensure connectivity before proceeding or try setting 'irc.server.port' to 8001 in scripts/connectors/submit_wikipedia_irc_config.sh\n"
  exit 1
fi

echo -e "\nStart streaming from the IRC source connector:"
${DIR}/connectors/submit_wikipedia_irc_config.sh

echo -e "\nProvide data mapping to Elasticsearch:"
${DIR}/dashboard/set_elasticsearch_mapping_bot.sh
${DIR}/dashboard/set_elasticsearch_mapping_count.sh

echo -e "\nStart streaming to Elasticsearch sink connector:"
${DIR}/connectors/submit_elastic_sink_config.sh

echo -e "\nStart Confluent Replicator:"
${DIR}/connectors/submit_replicator_config.sh

echo -e "\nConfigure Kibana dashboard:"
${DIR}/dashboard/configure_kibana_dashboard.sh

echo -e "\n\nStart KSQL engine and running queries:"
${DIR}/ksql/run_ksql.sh

echo -e "\nStart consumers for additional topics: WIKIPEDIANOBOT, EN_WIKIPEDIA_GT_1_COUNTS"
${DIR}/consumers/listen_WIKIPEDIANOBOT.sh
${DIR}/consumers/listen_EN_WIKIPEDIA_GT_1_COUNTS.sh

# Verify wikipedia.parsed topic is populated and schema is registered
MAX_WAIT=50
CUR_WAIT=0
echo -e "\nWaiting up to $MAX_WAIT seconds for wikipedia.parsed topic to be populated"
while [[ ! $(docker-compose exec schemaregistry curl -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt https://schemaregistry:8085/subjects) =~ "wikipedia.parsed-value" ]]; do
  sleep 10
  CUR_WAIT=$(( CUR_WAIT+10 ))
  #echo "CUR_WAIT: $CUR_WAIT"
  if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
    echo -e "\nERROR: IRC connector is not populating the Kafka topic wikipedia.parsed. Please troubleshoot with 'docker-compose ps' and 'docker-compose logs'.\n"
    exit 1
  fi
done

# Register the same schema for the replicated topic wikipedia.parsed.replica as was created for the original topic wikipedia.parsed
# In this case the replicated topic will register with the same schema ID as the original topic
SCHEMA=$(docker-compose exec schemaregistry curl -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt https://schemaregistry:8085/subjects/wikipedia.parsed-value/versions/latest | jq .schema)
docker-compose exec schemaregistry curl -X POST --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $SCHEMA}" https://schemaregistry:8085/subjects/wikipedia.parsed.replica-value/versions

echo -e "\nConfigure triggers and actions in Control Center:"
curl -X POST -H "Content-Type: application/json" -d '{"name":"Consumption Difference","clusterId":"'$(curl -X GET http://localhost:9021/2.0/clusters/kafka/ | jq --raw-output '.[0].clusterId')'","group":"connect-elasticsearch-ksql","metric":"CONSUMPTION_DIFF","condition":"GREATER_THAN","longValue":"0","lagMs":"10000"}' http://localhost:9021/2.0/alerts/triggers
curl -X POST -H "Content-Type: application/json" -d '{"name":"Under Replicated Partitions","clusterId":"default","condition":"GREATER_THAN","longValue":"0","lagMs":"60000","brokerClusters":{"brokerClusters":["'$(curl -X GET http://localhost:9021/2.0/clusters/kafka/ | jq --raw-output ".[0].clusterId")'"]},"brokerMetric":"UNDER_REPLICATED_TOPIC_PARTITIONS"}' http://localhost:9021/2.0/alerts/triggers
curl -X POST -H "Content-Type: application/json" -d '{"name":"Email Administrator","enabled":true,"triggerGuid":["'$(curl -X GET http://localhost:9021/2.0/alerts/triggers/ | jq --raw-output '.[0].guid')'","'$(curl -X GET http://localhost:9021/2.0/alerts/triggers/ | jq --raw-output '.[1].guid')'"],"maxSendRate":1,"intervalMs":"60000","email":{"address":"devnull@confluent.io","subject":"Confluent Control Center alert"}}' http://localhost:9021/2.0/alerts/actions

echo -e "\nDONE! Connect to Confluent Control Center at http://localhost:9021\n"
