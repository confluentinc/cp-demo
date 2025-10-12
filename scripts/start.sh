#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/helper/functions.sh
source ${DIR}/env.sh

#-------------------------------------------------------------------------------

# Do preflight checks
preflight_checks || exit

# Stop existing Docker containers
${DIR}/stop.sh

CLEAN=${CLEAN:-false}

# Build Kafka Connect image with connector plugins
build_connect_image

# Set the CLEAN variable to true if cert doesn't exist
if ! [[ -f "${DIR}/security/controlCenterAndKsqlDBServer-ca1-signed.crt" ]] || ! check_truststore_valid; then
  echo "INFO: Running with CLEAN=true because instructed or certificates don't yet exist."
  clean_demo_env
  CLEAN=true
fi

echo
echo "Environment parameters"
echo "  REPOSITORY=$REPOSITORY"
echo "  CONNECTOR_VERSION=$CONNECTOR_VERSION"
echo "  CLEAN=$CLEAN"
echo "  VIZ=$VIZ"
echo "  C3_KSQLDB_HTTPS=$C3_KSQLDB_HTTPS"
echo


if [[ "$CLEAN" == "true" ]] ; then
  create_certificates || exit 1
  if ! check_truststore_valid; then
    echo -e "\nERROR: Expected valid trusted certificates on the Kafka Connect server. Please troubleshoot and try again."
    exit 1
  fi
fi


#-------------------------------------------------------------------------------

# Bring up openldap
docker-compose up --no-recreate -d openldap
sleep 5
if [[ $(docker-compose ps openldap | grep Exit) =~ "Exit" ]] ; then
  echo "ERROR: openldap container could not start. Troubleshoot and try again. For troubleshooting instructions see https://docs.confluent.io/platform/current/tutorials/cp-demo/docs/troubleshooting.html"
  exit 1
fi



# Bring up tools
docker-compose up --no-recreate -d tools

# Add root CA to container (obviates need for supplying it at CLI login '--ca-cert-path')
docker-compose exec tools bash -c "cp /etc/kafka/secrets/snakeoil-ca-1.crt /usr/local/share/ca-certificates && /usr/sbin/update-ca-certificates"


# Bring up base kafka cluster
docker-compose up --no-recreate -d zookeeper kafka1 kafka2

# Verify MDS has started
MAX_WAIT=150
echo "Waiting up to $MAX_WAIT seconds for MDS to start"
retry $MAX_WAIT host_check_up kafka1 || exit 1
retry $MAX_WAIT host_check_up kafka2 || exit 1

echo "Creating role bindings for principals"
docker-compose exec tools bash -c "/tmp/helper/create-role-bindings.sh" || exit 1

# Workaround for setting min ISR on topic _confluent-metadata-auth
docker-compose exec kafka1 kafka-configs \
   --bootstrap-server kafka1:12091 \
   --entity-type topics \
   --entity-name _confluent-metadata-auth \
   --alter \
   --add-config min.insync.replicas=1

#-------------------------------------------------------------------------------


# Bring up more containers
docker-compose up --no-recreate -d schemaregistry connect control-center

echo
echo -e "Create topics in Kafka cluster:"
docker-compose exec tools bash -c "/tmp/helper/create-topics.sh" || exit 1

# Verify Kafka Connect Worker has started
MAX_WAIT=240
echo -e "\nWaiting up to $MAX_WAIT seconds for Connect to start"
retry $MAX_WAIT host_check_up connect || exit 1

#-------------------------------------------------------------------------------

echo -e "\nStart streaming from the Wikipedia SSE source connector:"
${DIR}/connectors/submit_wikipedia_sse_config.sh || exit 1

# Verify connector is running
MAX_WAIT=120
echo
echo "Waiting up to $MAX_WAIT seconds for connector to be in RUNNING state"
retry $MAX_WAIT check_connector_status_running "wikipedia-sse" || exit 1

# Verify wikipedia.parsed topic is populated and schema is registered
MAX_WAIT=120
echo
echo -e "Waiting up to $MAX_WAIT seconds for subject wikipedia.parsed-value (for topic wikipedia.parsed) to be registered in Schema Registry"
retry $MAX_WAIT host_check_schema_registered || exit 1

#-------------------------------------------------------------------------------

# Verify Confluent Control Center has started
MAX_WAIT=300
echo
echo "Waiting up to $MAX_WAIT seconds for Confluent Control Center to start"
retry $MAX_WAIT host_check_up control-center || exit 1

echo -e "\nConfluent Control Center modifications:"
${DIR}/helper/control-center-modifications.sh
echo


#-------------------------------------------------------------------------------

# Start more containers
docker-compose up --no-recreate -d ksqldb-server ksqldb-cli restproxy

# Verify ksqlDB server has started
echo
echo
MAX_WAIT=120
echo -e "\nWaiting up to $MAX_WAIT seconds for ksqlDB server to start"
retry $MAX_WAIT host_check_up ksqldb-server || exit 1

echo -e "\nRun ksqlDB queries:"
${DIR}/ksqlDB/run_ksqlDB.sh

if [[ "$VIZ" == "true" ]]; then
  build_viz || exit 1
fi

echo -e "\nStart additional consumers to read from topics WIKIPEDIANOBOT, WIKIPEDIA_COUNT_GT_1"
${DIR}/consumers/listen_WIKIPEDIANOBOT.sh
${DIR}/consumers/listen_WIKIPEDIA_COUNT_GT_1.sh

echo
echo
echo "Start the Kafka Streams application wikipedia-activity-monitor"
docker-compose up --no-recreate -d streams-demo
echo "..."


#-------------------------------------------------------------------------------


# Verify Docker containers started
if [[ $(docker-compose ps) =~ "Exit 137" ]]; then
  echo -e "\nERROR: At least one Docker container did not start properly, see 'docker-compose ps'. Did you increase the memory available to Docker to at least 8 GB (default is 2 GB)?\n"
  exit 1
fi

echo
echo -e "\nAvailable LDAP users:"
#docker-compose exec openldap ldapsearch -x -h localhost -b dc=confluentdemo,dc=io -D "cn=admin,dc=confluentdemo,dc=io" -w admin | grep uid:
curl -u mds:mds -X POST "https://localhost:8091/security/1.0/principals/User%3Amds/roles/UserAdmin" \
  -H "accept: application/json" -H "Content-Type: application/json" \
  -d "{\"clusters\":{\"kafka-cluster\":\"does_not_matter\"}}" \
  --cacert ${DIR}/security/snakeoil-ca-1.crt --tlsv1.2
curl -u mds:mds -X POST "https://localhost:8091/security/1.0/rbac/principals" --silent \
  -H "accept: application/json"  -H "Content-Type: application/json" \
  -d "{\"clusters\":{\"kafka-cluster\":\"does_not_matter\"}}" \
  --cacert ${DIR}/security/snakeoil-ca-1.crt --tlsv1.2 | jq '.[]'

# Do poststart_checks
poststart_checks


cat << EOF

----------------------------------------------------------------------------------------------------
DONE! From your browser:

  Confluent Control Center (login superUser/superUser for full access):
     $C3URL

EOF

if [[ "$VIZ" == "true" ]]; then
cat << EOF
  Kibana
     $kibanaURL

EOF
fi

cat << EOF
Want more? Learn how to replicate data from the on-prem cluster to Confluent Cloud:

     https://docs.confluent.io/platform/current/tutorials/cp-demo/docs/hybrid-cloud.html

Use Confluent Cloud promo code CPDEMO50 to receive \$50 free usage
----------------------------------------------------------------------------------------------------

EOF
