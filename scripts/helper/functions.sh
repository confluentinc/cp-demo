#!/bin/bash

retry() {
    local -r -i max_wait="$1"; shift
    local -r cmd="$@"

    local -i sleep_interval=5
    local -i curr_wait=0

    until $cmd
    do
        if (( curr_wait >= max_wait ))
        then
            echo "ERROR: Failed after $curr_wait seconds. Please troubleshoot and run again. For troubleshooting instructions see https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html#troubleshooting"
            return 1
        else
            printf "."
            curr_wait=$((curr_wait+sleep_interval))
            sleep $sleep_interval
        fi
    done
    printf "\n"
}

verify_installed()
{
  local cmd="$1"
  if [[ $(type $cmd 2>&1) =~ "not found" ]]; then
    echo -e "\nERROR: This script requires '$cmd'. Please install '$cmd' and run again.\n"
    exit 1
  fi
  return 0
}

preflight_checks()
{
  # Verify appropriate tools are installed on host
  for cmd in curl jq docker-compose keytool docker openssl xargs awk; do
    verify_installed $cmd || exit 1
  done

  # Verify Docker memory is at least 8 GB
  if [[ $(docker system info --format '{{.MemTotal}}') -lt 8000000000 ]]; then
    echo -e "\nWARNING: Memory available to Docker should be at least 8 GB (default is 2 GB), otherwise cp-demo may not work properly.\n"
    if [[ "$VIZ" == "true" ]]; then
      echo -e "ERROR: Cannot proceed with Docker memory less than 8 GB when 'VIZ=true' (enables Elasticsearch and Kibana).  Either increase memory available to Docker or restart cp-demo with 'VIZ=false' (see https://docs.confluent.io/platform/current/tutorials/cp-demo/docs/index.html#start)\n"
      exit 1
    fi
    sleep 3
  fi

  # Verify Docker CPU cores is increased to at least 2
  if [[ $(docker system info --format '{{.NCPU}}') -lt 2 ]]; then
    echo -e "\nWARNING: Number of CPU cores available to Docker must be at least 2, otherwise cp-demo may not work properly.\n"
    sleep 3
  fi

  return 0

}

get_kafka_cluster_id_from_container()
{
  KAFKA_CLUSTER_ID=$(curl -s https://kafka1:8091/v1/metadata/id --cert /etc/kafka/secrets/mds.certificate.pem --key /etc/kafka/secrets/mds.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt | jq -r ".id")

  if [ -z "$KAFKA_CLUSTER_ID" ]; then
    echo "Failed to retrieve Kafka cluster id"
    exit 1
  fi
  echo $KAFKA_CLUSTER_ID
  return 0
}

clean_demo_env()
{
  local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

  echo "CLEAN=true -> deleting existing certificates and local Connect Docker image generated by cp-demo"

  # Remove existing keys and certificates
  (cd ${DIR}/../security && ./certs-clean.sh)

  # Remove existing Connect image
  docker rmi -f localbuild/connect:${CONFLUENT_DOCKER_TAG}-${CONNECTOR_VERSION}
}

create_certificates()
{
  local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

  # Generate keys and certificates used for SSL
  echo -e "Generate keys and certificates used for SSL (see ${DIR}/security)"
  (cd ${DIR}/../security && ./certs-create.sh)

  # Generating public and private keys for token signing
  echo "Generating public and private keys for token signing"
  mkdir -p ${DIR}/../security/keypair
  openssl genrsa -out ${DIR}/../security/keypair/keypair.pem 2048
  openssl rsa -in ${DIR}/../security/keypair/keypair.pem -outform PEM -pubout -out ${DIR}/../security/keypair/public.pem

  # Enable Docker appuser to read files when created by a different UID
  echo -e "Setting insecure permissions on some files in ${DIR}/../security for demo purposes\n"
  chmod 644 ${DIR}/../security/keypair/keypair.pem
  chmod 644 ${DIR}/../security/*.key
}

build_connect_image()
{
  echo
  echo "Building custom Docker image with Connect version ${CONFLUENT_DOCKER_TAG} and connector version ${CONNECTOR_VERSION}"

  local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
  
  if [[ "${CONNECTOR_VERSION}" =~ "SNAPSHOT" ]]; then
    DOCKERFILE="${DIR}/../../Dockerfile-local"
  else
    DOCKERFILE="${DIR}/../../Dockerfile-confluenthub"
  fi
  echo "docker build --build-arg CP_VERSION=${CONFLUENT_DOCKER_TAG} --build-arg CONNECTOR_VERSION=${CONNECTOR_VERSION} -t localbuild/connect:${CONFLUENT_DOCKER_TAG}-${CONNECTOR_VERSION} -f $DOCKERFILE ${DIR}/../../."
  docker build --build-arg CP_VERSION=${CONFLUENT_DOCKER_TAG} --build-arg CONNECTOR_VERSION=${CONNECTOR_VERSION} -t localbuild/connect:${CONFLUENT_DOCKER_TAG}-${CONNECTOR_VERSION} -f $DOCKERFILE ${DIR}/../../. || {
    echo "ERROR: Docker image build failed. Please troubleshoot and try again. For troubleshooting instructions see https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html#troubleshooting"
    exit 1
  }
  
  # Copy the updated kafka.connect.truststore.jks back to the host
  docker create --name cp-demo-tmp-connect localbuild/connect:${CONFLUENT_DOCKER_TAG}-${CONNECTOR_VERSION}
  docker cp cp-demo-tmp-connect:/tmp/kafka.connect.truststore.jks ${DIR}/../security/kafka.connect.truststore.jks
  docker rm cp-demo-tmp-connect
}

build_viz()
{
  local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

  echo
  echo
  echo "VIZ=true: running Elasticsearch, Elasticsearch sink connector, and Kibana"

  docker-compose up -d elasticsearch kibana

  # Verify Elasticsearch is ready
  MAX_WAIT=240
  echo
  echo -e "\nWaiting up to $MAX_WAIT seconds for Elasticsearch to be ready"
  retry $MAX_WAIT host_check_elasticsearch_ready || exit 1
  echo -e "\nProvide data mapping to Elasticsearch:"
  ${DIR}/../dashboard/set_elasticsearch_mapping_bot.sh
  ${DIR}/../dashboard/set_elasticsearch_mapping_count.sh
  echo

  echo -e "\nStart streaming to Elasticsearch sink connector:"
  ${DIR}/../connectors/submit_elastic_sink_config.sh
  echo

  # Verify Kibana is ready
  MAX_WAIT=120
  echo
  echo -e "\nWaiting up to $MAX_WAIT seconds for Kibana to be ready"
  retry $MAX_WAIT host_check_kibana_ready || exit 1
  echo -e "\nConfigure Kibana dashboard:"
  ${DIR}/../dashboard/configure_kibana_dashboard.sh
  echo

  return 0
}

host_check_control_center_up()
{
  FOUND=$(docker-compose logs control-center | grep "Started NetworkTrafficServerConnector")
  if [ -z "$FOUND" ]; then
    return 1
  fi
  return 0
}

host_check_mds_up()
{
  FOUND=$(docker-compose logs kafka1 | grep "Started NetworkTrafficServerConnector")
  if [ -z "$FOUND" ]; then
    return 1
  fi
  return 0
}

host_check_ksqlDBserver_up()
{
  KSQLDB_CLUSTER_ID=$(curl -s -u ksqlDBUser:ksqlDBUser http://localhost:8088/info | jq -r ".KsqlServerInfo.ksqlServiceId")
  if [ "$KSQLDB_CLUSTER_ID" == "ksql-cluster" ]; then
    return 0
  fi
  return 1
}

host_check_connect_up()
{
  FOUND=$(docker-compose logs connect | grep "Herder started")
  if [ -z "$FOUND" ]; then
    return 1
  fi
  return 0
}

host_check_schema_registered()
{
  FOUND=$(docker-compose exec schemaregistry curl -s -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u superUser:superUser https://schemaregistry:8085/subjects | grep "wikipedia.parsed-value")
  if [ -z "$FOUND" ]; then
    return 1
  fi
  return 0
}

host_check_elasticsearch_ready()
{
  ES_NAME=$(curl -s -XGET http://localhost:9200/_cluster/health | jq -r ".cluster_name")
  if [ "$ES_NAME" == "elasticsearch-cp-demo" ]; then
    return 0
  fi
  return 1
}

host_check_kibana_ready()
{
  KIBANA_STATUS=$(curl -s -XGET http://localhost:5601/api/status | jq -r ".status.overall.state")
  if [ "$KIBANA_STATUS" == "green" ]; then
    return 0
  fi
  return 1
}

mds_login()
{
  MDS_URL=$1
  SUPER_USER=$2
  SUPER_USER_PASSWORD=$3

  # Log into MDS
  if [[ $(type expect 2>&1) =~ "not found" ]]; then
    echo "'expect' is not found. Install 'expect' and try again"
    exit 1
  fi
  echo -e "\n# Login"
  OUTPUT=$(
  expect <<END
    log_user 1
    spawn confluent login --ca-cert-path /etc/kafka/secrets/snakeoil-ca-1.crt --url $MDS_URL
    expect "Username: "
    send "${SUPER_USER}\r";
    expect "Password: "
    send "${SUPER_USER_PASSWORD}\r";
    expect "Logged in as "
    set result $expect_out(buffer)
END
  )
  echo "$OUTPUT"
  if [[ ! "$OUTPUT" =~ "Logged in as" ]]; then
    echo "Failed to log into MDS.  Please check all parameters and run again"
    exit 1
  fi
}

create_topic() {

  local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

  broker_host_port=$1
  cluster_id=$2
  topic_name=$3
  confluent_value_schema_validation=$4
  auth=$5

  RESULT=$(curl -sS -X POST \
    -u ${auth} \
    --cacert /etc/kafka/secrets/snakeoil-ca-1.crt \
    --header 'Content-Type: application/json' \
    --data-binary @<(jq -n --arg topic_name "${topic_name}" --arg confluent_value_schema_validation "${confluent_value_schema_validation}" -f ${DIR}/topic.jq) \
    "https://${broker_host_port}/kafka/v3/clusters/${cluster_id}/topics") && RC=$? || RC=$?

  echo $RESULT | jq || true

  if [[ $RC -ne 0 || -z $RESULT || $RESULT =~ "error_code" ]]; then
    echo "ERROR: create topic failed $RESULT"
    return 1
  fi

  return 0
}
