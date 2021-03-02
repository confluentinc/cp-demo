#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/helper/functions.sh
source ${DIR}/env.sh

#-------------------------------------------------------------------------------

# Do preflight checks
preflight_checks || exit

# Stop existing Docker containers
${DIR}/stop.sh

# Regenerate certificates and the Connect Docker image if any of the following conditions are true
if [[ "$CLEAN" == "true" ]] || \
 ! [[ -f "${DIR}/security/controlCenterAndKsqlDBServer-ca1-signed.crt" ]] || \
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
echo "  CLEAN=$CLEAN"
echo "  VIZ=$VIZ"
echo "  C3_KSQLDB_HTTPS=$C3_KSQLDB_HTTPS"
echo

if [[ "$CLEAN" == "true" ]] ; then
  create_certificates
fi

#-------------------------------------------------------------------------------

# Bring up openldap
docker-compose up -d openldap
sleep 5
if [[ $(docker-compose ps openldap | grep Exit) =~ "Exit" ]] ; then
  echo "ERROR: openldap container could not start. Troubleshoot and try again. For troubleshooting instructions see https://docs.confluent.io/platform/current/tutorials/cp-demo/docs/troubleshooting.html"
  exit 1
fi

# Bring up base cluster and Confluent CLI
docker-compose up -d zookeeper kafka1 kafka2 tools

# Verify MDS has started
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for MDS to start"
retry $MAX_WAIT host_check_mds_up || exit 1
sleep 5

# Add root CA to container (obviates need for supplying it at CLI login '--ca-cert-path')
docker-compose exec tools bash -c "cp /etc/kafka/secrets/snakeoil-ca-1.crt /usr/local/share/ca-certificates && /usr/sbin/update-ca-certificates"

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

# Build custom Kafka Connect image with required jars
if [[ "$CLEAN" == "true" ]] ; then
  build_connect_image || exit 1
fi

# Bring up more containers
docker-compose up -d schemaregistry connect control-center

echo
echo -e "Create topics in Kafka cluster:"
docker-compose exec tools bash -c "/tmp/helper/create-topics.sh" || exit 1

# Verify Confluent Control Center has started
MAX_WAIT=300
echo
echo "Waiting up to $MAX_WAIT seconds for Confluent Control Center to start"
retry $MAX_WAIT host_check_control_center_up || exit 1

echo -e "\nConfluent Control Center modifications:"
${DIR}/helper/control-center-modifications.sh
echo

# Verify Kafka Connect Worker has started
MAX_WAIT=240
echo -e "\nWaiting up to $MAX_WAIT seconds for Connect to start"
retry $MAX_WAIT host_check_connect_up "connect" || exit 1
sleep 2 # give connect an exta moment to fully mature

NUM_CERTS=$(docker-compose exec connect keytool --list --keystore /etc/kafka/secrets/kafka.connect.truststore.jks --storepass confluent | grep trusted | wc -l)
if [[ "$NUM_CERTS" -eq "1" ]]; then
  echo -e "\nERROR: Connect image did not build properly.  Expected ~147 trusted certificates but got $NUM_CERTS. Please troubleshoot and try again."
  exit 1
fi

echo
docker-compose up -d ksqldb-server ksqldb-cli restproxy
echo "..."

# Verify Docker containers started
if [[ $(docker-compose ps) =~ "Exit 137" ]]; then
  echo -e "\nERROR: At least one Docker container did not start properly, see 'docker-compose ps'. Did you increase the memory available to Docker to at least 8 GB (default is 2 GB)?\n"
  exit 1
fi

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

# Register the same schema for the replicated topic wikipedia.parsed.replica as was created for the original topic wikipedia.parsed
# In this case the replicated topic will register with the same schema ID as the original topic
echo -e "\nRegister subject wikipedia.parsed.replica-value in Schema Registry"
SCHEMA=$(docker-compose exec schemaregistry curl -s -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u superUser:superUser https://schemaregistry:8085/subjects/wikipedia.parsed-value/versions/latest | jq .schema)
docker-compose exec schemaregistry curl -X POST --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{\"schema\": $SCHEMA}" -u superUser:superUser https://schemaregistry:8085/subjects/wikipedia.parsed.replica-value/versions

echo
echo -e "\nStart Confluent Replicator to loopback to on-prem cluster:"
${DIR}/connectors/submit_replicator_config.sh || exit 1

#-------------------------------------------------------------------------------

# Verify ksqlDB server has started
echo
echo
MAX_WAIT=120
echo -e "\nWaiting up to $MAX_WAIT seconds for ksqlDB server to start"
retry $MAX_WAIT host_check_ksqlDBserver_up || exit 1
echo -e "\nRun ksqlDB queries:"
${DIR}/ksqlDB/run_ksqlDB.sh

echo -e "\nStart additional consumers to read from topics WIKIPEDIANOBOT, WIKIPEDIA_COUNT_GT_1"
${DIR}/consumers/listen_WIKIPEDIANOBOT.sh
${DIR}/consumers/listen_WIKIPEDIA_COUNT_GT_1.sh

echo
echo
echo "Start the Kafka Streams application wikipedia-activity-monitor"
docker-compose up -d streams-demo
echo "..."

#-------------------------------------------------------------------------------

if [[ "$VIZ" == "true" ]]; then
  build_viz || exit 1
fi

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
     http://localhost:5601/app/dashboards#/view/Overview

EOF
fi

cat << EOF
Want more? Learn how to replicate data from the on-prem cluster to Confluent Cloud:

     https://docs.confluent.io/platform/current/tutorials/cp-demo/docs/hybrid-cloud.html

Use Confluent Cloud promo code CPDEMO50 to receive \$50 free usage
----------------------------------------------------------------------------------------------------

EOF
