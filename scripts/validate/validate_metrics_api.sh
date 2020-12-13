#!/bin/bash
  
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../helper/functions.sh
source ${DIR}/../../.env
source ${DIR}/../env.sh

currentTime=$(date -Is)
CURRENT_TIME_MINUS_1HR=$(date -Is -d '-1 hour')
CURRENT_TIME_PLUS_1HR=$(date -Is -d '+1 hour')
echo "times: $CURRENT_TIME_MINUS_1HR / $CURRENT_TIME_PLUS_1HR"

echo "DIR1: ${DIR}"

echo
echo "This example uses real Confluent Cloud resources."
echo "To avoid unexpected charges, carefully evaluate the cost of resources before launching the script and ensure all resources are destroyed after you are done running it."
echo "(Use Confluent Cloud promo ``C50INTEG`` to receive \$50 free usage)"
read -p "Do you still want to run this script? [y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
fi

# Log into Confluent Cloud CLI
echo
ccloud login --save || exit 1

# Create credentials for the cloud resource
CREDENTIALS=$(ccloud api-key create --resource cloud -o json) || exit 1
METRICS_API_KEY=$(echo "$CREDENTIALS" | jq -r .key)
METRICS_API_SECRET=$(echo "$CREDENTIALS" | jq -r .secret)
echo "export METRICS_API_KEY=$METRICS_API_KEY"
echo "export METRICS_API_SECRET=$METRICS_API_SECRET"

# Enable Confluent Telemetry Reporter
# TODO: docker-compose exec kafka1 kafka-configs --bootstrap-server kafka1:12091 --describe --entity-type brokers is empty
# TODO: API secret shown in logs
echo
echo "Enabling Confluent Telemetry Reporter to send metrics to Confluent Cloud"
for brokerNum in 1 2; do
  docker-compose exec kafka${brokerNum} kafka-configs \
    --bootstrap-server kafka${brokerNum}:1209${brokerNum} \
    --alter \
    --entity-type brokers \
    --entity-default \
    --add-config "confluent.telemetry.enabled=true,confluent.telemetry.api.key='${METRICS_API_KEY}',confluent.telemetry.api.secret='${METRICS_API_SECRET}'"
done

# Create a new ccloud-stack
echo
echo "Configure a new Confluent Cloud ccloud-stack"
wget -O ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh
source ./ccloud_library.sh
ccloud::create_ccloud_stack
SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
KAFKA_CLUSTER_ID=$(ccloud kafka cluster list -o json | jq -c -r '.[] | select (.name == "'"demo-kafka-cluster-$SERVICE_ACCOUNT_ID"'")' | jq -r .id)

echo "DIR2: ${DIR}"

# Create parameters customized for Confluent Cloud instance created above
wget -O ccloud-generate-cp-configs.sh https://raw.githubusercontent.com/confluentinc/examples/latest/ccloud/ccloud-generate-cp-configs.sh
chmod 744 ./ccloud-generate-cp-configs.sh
./ccloud-generate-cp-configs.sh $CONFIG_FILE
source "delta_configs/env.delta"

echo -e "\nStart Confluent Replicator to Confluent Cloud:"
export REPLICATOR_NAME=replicate-topic-to-ccloud

back="origin"
echo "back: $back"

if [[ "$back" == "destination" ]]; then

####### Separate connect worker backed to CCloud (destination)
# TODO: current issue: http://localhost:8087/permissions 404 (C3?)
# TODO: no metrics available
docker-compose up -d replicator-to-ccloud
# Verify Confluent Replicator's Connect Worker has started
MAX_WAIT=120
echo -e "\nWaiting up to $MAX_WAIT seconds for Confluent Replicator's Connect Worker to start"
retry $MAX_WAIT host_check_connect_up "replicator-to-ccloud" || exit 1
sleep 2 # give connect an exta moment to fully mature
${DIR}/../connectors/submit_replicator_to_ccloud_config_backed_ccloud.sh

else

####### Shared connect worker backed to cp-demo (source)
# TODO: current issue: Unexpected SASL mechanism: PLAIN
# Create role binding
CONNECTOR_SUBMITTER="User:connectorSubmitter"
KAFKA_CLUSTER_ID=$(curl -s https://localhost:8091/v1/metadata/id --tlsv1.2 --cacert ${DIR}/../security/snakeoil-ca-1.crt | jq -r ".id")
CONNECT=connect-cluster
${DIR}/../helper/refresh_mds_login.sh
docker-compose exec tools bash -c "confluent iam rolebinding create \
    --principal $CONNECTOR_SUBMITTER \
    --role ResourceOwner \
    --resource Connector:${REPLICATOR_NAME} \
    --kafka-cluster-id $KAFKA_CLUSTER_ID \
    --connect-cluster-id $CONNECT"
${DIR}/../connectors/submit_replicator_to_ccloud_config.sh
fi

# Verify Replicator to Confluent Cloud has started
#echo
#MAX_WAIT=120
#echo "Waiting up to $MAX_WAIT seconds for Replicator to Confluent Cloud to start"
#retry $MAX_WAIT check_connector_status_running ${REPLICATOR_NAME} || exit 1
#echo "Replicator started!"

echo "sleeping 120 seconds"
sleep 120

echo "DIR3: ${DIR}"

echo "Sleeping 30s"
sleep 30

# TODO: is possible to do last hour instead of fixed interval range?

# Hosted
DATA=$(eval "cat <<EOF       
$(<${DIR}/metrics_query_onprem.json)
EOF
")
echo "DATA: $DATA"
curl -u ${METRICS_API_KEY}:${METRICS_API_SECRET} \
     --header 'content-type: application/json' \
     --data "${DATA}" \
     https://api.telemetry.confluent.cloud/v1/metrics/hosted-monitoring/query \
        | jq .

# Confluent Cloud
DATA=$(eval "cat <<EOF       
$(<${DIR}/metrics_query_ccloud.json)
EOF
")
echo "DATA: $DATA"
curl -u ${METRICS_API_KEY}:${METRICS_API_SECRET} \
     --header 'content-type: application/json' \
     --data "${DATA}" \
     https://api.telemetry.confluent.cloud/v1/metrics/cloud/query \
        | jq .

echo
echo "Sleeping 120s"
sleep 120

#### Disable ####

echo "DIR4: ${DIR}"
echo "Destroying all resources"

docker-compose rm -s replicator-to-ccloud

for brokerNum in 1 2; do
  docker-compose exec kafka${brokerNum} kafka-configs \
    --bootstrap-server kafka${brokerNum}:1209${brokerNum} \
        --alter \
        --entity-type brokers \
        --entity-default \
        --delete-config "confluent.telemetry.enabled,confluent.telemetry.api.key,confluent.telemetry.api.secret"
done

ccloud api-key delete $METRICS_API_KEY

ccloud::destroy_ccloud_stack $SERVICE_ACCOUNT_ID
echo "DIR4: ${DIR}"

