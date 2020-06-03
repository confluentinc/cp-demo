#!/bin/bash

# With RBAC enabled, C3 communication thru its REST endpoint requires JSON Web Tokens (JWT)
JWT_TOKEN=$(curl -s -u controlcenterAdmin:controlcenterAdmin http://localhost:9021/api/metadata/security/1.0/authenticate | jq -r .auth_token)

# If you have 'jq'
clusterId=$(curl -s -X GET -H "Authorization: Bearer ${JWT_TOKEN}" http://localhost:9021/2.0/clusters/kafka/ | jq --raw-output '.[0].clusterId')
# If you don't have 'jq'
#clusterId=$(curl -s -X GET -H "Authorization: Bearer ${JWT_TOKEN}" http://localhost:9021/2.0/clusters/kafka/ | awk -v FS="(clusterId\":\"|\",\"displayName)" '{print $2}')

echo -e "\nRename the cluster in Control Center from ${clusterId} to Kafka Raleigh"
curl -X PATCH -H "Authorization: Bearer ${JWT_TOKEN}" -H "Content-Type: application/merge-patch+json" -d '{"displayName":"Kafka Raleigh"}' http://localhost:9021/2.0/clusters/kafka/$clusterId

echo -e "\nConfigure triggers and actions in Control Center:"
curl -X POST -H "Authorization: Bearer ${JWT_TOKEN}" -H "Content-Type: application/json" -d '{"name":"Consumption Difference","clusterId":"'$clusterId'","group":"connect-elasticsearch-ksqldb","metric":"CONSUMPTION_DIFF","condition":"GREATER_THAN","longValue":"0","lagMs":"10000"}' http://localhost:9021/2.0/alerts/triggers

curl -X POST -H "Authorization: Bearer ${JWT_TOKEN}" -H "Content-Type: application/json" -d '{"name":"Under Replicated Partitions","clusterId":"default","condition":"GREATER_THAN","longValue":"0","lagMs":"60000","brokerClusters":{"brokerClusters":["'$clusterId'"]},"brokerMetric":"UNDER_REPLICATED_TOPIC_PARTITIONS"}' http://localhost:9021/2.0/alerts/triggers

curl -X POST -H "Authorization: Bearer ${JWT_TOKEN}" -H "Content-Type: application/json" -d '{"name":"Email Administrator","enabled":true,"triggerGuid":["'$(curl -s -X GET -H "Authorization: Bearer ${JWT_TOKEN}" http://localhost:9021/2.0/alerts/triggers/ | jq --raw-output '.[0].guid')'","'$(curl -s -X GET -H "Authorization: Bearer ${JWT_TOKEN}" http://localhost:9021/2.0/alerts/triggers/ | jq --raw-output '.[1].guid')'"],"maxSendRate":1,"intervalMs":"60000","email":{"address":"devnull@confluent.io","subject":"Confluent Control Center alert"}}' http://localhost:9021/2.0/alerts/actions

