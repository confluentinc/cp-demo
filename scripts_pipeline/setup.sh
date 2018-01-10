#!/bin/bash

if [[ ! -d connect-plugins/kafka-connect-irc ]]; then
  echo -e "There is no connect-plugins path. Did you remember to run 'make clean all'?\n"
  exit 1
fi

DOCKER_MEMORY=$(docker system info | grep Memory | grep -o "[0-9\.]\+")
if (( $(echo "$DOCKER_MEMORY 7.0" | awk '{print ($1 < $2)}') )); then
  echo -e "\nWARNING: Did you remember to increase the memory available to Docker to at least 8GB (default is 2GB)? Demo may otherwise not work properly.\n"
  sleep 3
fi

if [[ $(docker-compose ps) =~ "Exit 137" ]]; then
  echo -e "At least one Docker container did not start properly, see 'docker-compose ps'. Did you remember to increase the memory available to Docker to at least 8GB (default is 2GB)?\n"
  exit 1
fi

if [[ ! $(docker-compose logs control-center) =~ "Started NetworkTrafficServerConnector" ]]; then
  echo -e "The logs in control-center container do not show 'Started NetworkTrafficServerConnector' yet. Please wait a minute before running this script again. Did you remember to run 'make clean all'?\n"
  exit 1
fi

echo -e "\nRename the cluster in Control Center:"
curl -X PATCH  -H "Content-Type: application/merge-patch+json" -d '{"displayName":"Kafka Raleigh"}' http://localhost:9021/2.0/clusters/kafka/$(curl -X get http://localhost:9021/2.0/clusters/kafka/ | jq --raw-output .[0].clusterId)
# If you don't have `jq`
#curl -X PATCH  -H "Content-Type: application/merge-patch+json" -d '{"displayName":"Kafka Raleigh"}' http://localhost:9021/2.0/clusters/kafka/$(curl -X get http://localhost:9021/2.0/clusters/kafka/ | awk -v FS="(clusterId\":\"|\",\"displayName)" '{print $2}' )

echo -e "\nStart streaming from the IRC source connector:"
./scripts_pipeline/submit_wikipedia_irc_config.sh

echo -e "\nProvide data mapping to Elasticsearch:"
./scripts_pipeline/set_elasticsearch_mapping.sh

echo -e "\nStart streaming to Elasticsearch sink connector:"
./scripts_pipeline/submit_elastic_sink_config.sh

echo -e "\nStart Confluent Replicator:"
./scripts_pipeline/submit_replicator_config.sh

echo -e "\nConfigure Kibana dashboard:"
./scripts_pipeline/configure_kibana_dashboard.sh

echo -e "\nSleeping 50 seconds"
sleep 50

# Workaround for KAFKA-6252 with the IRC connector
docker-compose restart connect

echo -e "\nConfigure triggers and actions in Control Center:"
curl -X POST -H "Content-Type: application/json" -d '{"name":"Consumption Difference","clusterId":"'$(curl -X get http://localhost:9021/2.0/clusters/kafka/ | jq --raw-output .[0].clusterId)'","group":"connect-elasticsearch-ksql","metric":"CONSUMPTION_DIFF","condition":"GREATER_THAN","longValue":"0","lagMs":"5000"}' http://localhost:9021/2.0/alerts/triggers
curl -X POST -H "Content-Type: application/json" -d '{"name":"Under Replicated Partitions","clusterId":"default","condition":"GREATER_THAN","longValue":"0","lagMs":"60000","brokerClusters":{"brokerClusters":["'$(curl -X get http://localhost:9021/2.0/clusters/kafka/ | jq --raw-output ".[0].clusterId")'"]},"brokerMetric":"UNDER_REPLICATED_TOPIC_PARTITIONS"}' http://localhost:9021/2.0/alerts/triggers
curl -X POST -H "Content-Type: application/json" -d '{"name":"Email Administrator","enabled":true,"triggerGuid":["'$(curl -X get http://localhost:9021/2.0/alerts/triggers/ | jq --raw-output .[0].guid)'","'$(curl -X get http://localhost:9021/2.0/alerts/triggers/ | jq --raw-output .[1].guid)'"],"maxSendRateNumerator":1,"intervalMs":"60000","email":{"address":"devnull@confluent.io","subject":"Confluent Control Center alert"}}' http://localhost:9021/2.0/alerts/actions

echo -e "\nSleeping 30 seconds"
sleep 30

echo -e "\nDONE! Connect to Confluent Control Center at http://localhost:9021\n"
