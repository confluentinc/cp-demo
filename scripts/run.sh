#!/bin/bash

set -o nounset \
    -o errexit \
    -o verbose

# Verify jq is installed
if [[ $(type jq 2>&1) =~ "not found" ]]; then
  echo -e "\nERROR: This script requires 'jq'. Please install 'jq' and run again.\n"
  exit 1
fi

# Verify Docker memory is increased to at least 8GB
DOCKER_MEMORY=$(docker system info | grep Memory | grep -o "[0-9\.]\+")
if (( $(echo "$DOCKER_MEMORY 7.0" | awk '{print ($1 < $2)}') )); then
  echo -e "\nWARNING: Did you remember to increase the memory available to Docker to at least 8GB (default is 2GB)? Demo may otherwise not work properly.\n"
  sleep 3
fi

# Stop existing demo Docker containers
./scripts/reset_demo.sh

# Generate keys and certificates used for SSL
echo -e "Generate keys and certificates used for SSL"
(cd scripts/security && ./certs-create.sh)

# Bring up Docker Compose
echo -e "Bringing up Docker Compose"
docker-compose up -d

# Waiting for services to be ready, sleeping 90 seconds
echo -e "Waiting for services to be ready, sleeping 90 seconds"
sleep 90

# Verify Docker containers started
if [[ $(docker-compose ps) =~ "Exit 137" ]]; then
  echo -e "\nERROR: At least one Docker container did not start properly, see 'docker-compose ps'. Did you remember to increase the memory available to Docker to at least 8GB (default is 2GB)?\n"
  exit 1
fi

# Verify Confluent Control Center has started
if [[ ! $(docker-compose logs control-center) =~ "Started NetworkTrafficServerConnector" ]]; then
  echo -e "\nERROR: The logs in control-center container do not show 'Started NetworkTrafficServerConnector' yet. Please wait a minute before running this script again. Did you remember to run '(cd scripts/security && ./certs-create.sh)'?\n"
  exit 1
fi

# Verify Docker has the latest cp-kafka-connect image
if [[ $(docker-compose logs connect) =~ "server returned information about unknown correlation ID" ]]; then
  echo -e "\nERROR: Please update the cp-kafka-connect image with 'docker-compose pull'\n"
  exit 1
fi

echo -e "\nRename the cluster in Control Center:"
# If you have 'jq'
curl -X PATCH  -H "Content-Type: application/merge-patch+json" -d '{"displayName":"Kafka Raleigh"}' http://localhost:9021/2.0/clusters/kafka/$(curl -X get http://localhost:9021/2.0/clusters/kafka/ | jq --raw-output .[0].clusterId)
# If you don't have 'jq'
#curl -X PATCH  -H "Content-Type: application/merge-patch+json" -d '{"displayName":"Kafka Raleigh"}' http://localhost:9021/2.0/clusters/kafka/$(curl -X get http://localhost:9021/2.0/clusters/kafka/ | awk -v FS="(clusterId\":\"|\",\"displayName)" '{print $2}' )

echo -e "\nStart streaming from the IRC source connector:"
./scripts/connectors/submit_wikipedia_irc_config.sh

echo -e "\nProvide data mapping to Elasticsearch:"
./scripts/dashboard/set_elasticsearch_mapping_bot.sh
./scripts/dashboard/set_elasticsearch_mapping_count.sh

echo -e "\nStart streaming to Elasticsearch sink connector:"
./scripts/connectors/submit_elastic_sink_config.sh

echo -e "\nStart Confluent Replicator:"
./scripts/connectors/submit_replicator_config.sh

echo -e "\nConfigure Kibana dashboard:"
./scripts/dashboard/configure_kibana_dashboard.sh

echo -e "\n\nStart KSQL engine and running queries:"
./scripts/ksql/run_ksql.sh

echo -e "\nStart consumers for additional topics: WIKIPEDIANOBOT, EN_WIKIPEDIA_GT_1_COUNTS"
./scripts/consumers/listen_WIKIPEDIANOBOT.sh
./scripts/consumers/listen_EN_WIKIPEDIA_GT_1_COUNTS.sh

echo -e "\nWaiting for KSQL queries to start, sleeping 50 seconds"
sleep 50

echo -e "\nConfigure triggers and actions in Control Center:"
curl -X POST -H "Content-Type: application/json" -d '{"name":"Consumption Difference","clusterId":"'$(curl -X get http://localhost:9021/2.0/clusters/kafka/ | jq --raw-output .[0].clusterId)'","group":"connect-elasticsearch-ksql","metric":"CONSUMPTION_DIFF","condition":"GREATER_THAN","longValue":"0","lagMs":"10000"}' http://localhost:9021/2.0/alerts/triggers
curl -X POST -H "Content-Type: application/json" -d '{"name":"Under Replicated Partitions","clusterId":"default","condition":"GREATER_THAN","longValue":"0","lagMs":"60000","brokerClusters":{"brokerClusters":["'$(curl -X get http://localhost:9021/2.0/clusters/kafka/ | jq --raw-output ".[0].clusterId")'"]},"brokerMetric":"UNDER_REPLICATED_TOPIC_PARTITIONS"}' http://localhost:9021/2.0/alerts/triggers
curl -X POST -H "Content-Type: application/json" -d '{"name":"Email Administrator","enabled":true,"triggerGuid":["'$(curl -X get http://localhost:9021/2.0/alerts/triggers/ | jq --raw-output .[0].guid)'","'$(curl -X get http://localhost:9021/2.0/alerts/triggers/ | jq --raw-output .[1].guid)'"],"maxSendRateNumerator":1,"intervalMs":"60000","email":{"address":"devnull@confluent.io","subject":"Confluent Control Center alert"}}' http://localhost:9021/2.0/alerts/actions

echo -e "\nWaiting for everything to stabilize, sleeping 30 seconds"
sleep 30

echo -e "\nDONE! Connect to Confluent Control Center at http://localhost:9021\n"
