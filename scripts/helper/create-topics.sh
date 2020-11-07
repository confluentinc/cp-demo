#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

# Create Kafka topic users, using appSA principal
./create-topic.sh appSA.config users

# Create Kafka topics with prefix wikipedia, using connectorSA principal
./create-topic.sh connectorSA_without_interceptors_ssl.config wikipedia.parsed
./create-topic.sh connectorSA_without_interceptors_ssl.config wikipedia.parsed.count-by-domain
./create-topic.sh connectorSA_without_interceptors_ssl.config wikipedia.failed

# Create Kafka topics with prefix WIKIPEDIA or EN_WIKIPEDIA, using ksqlDBUser principal
for t in WIKIPEDIABOT WIKIPEDIANOBOT EN_WIKIPEDIA_GT_1 EN_WIKIPEDIA_GT_1_COUNTS
do
  ./create-topic.sh ksqlDBUser_without_interceptors_ssl.config $t
done
