#!/bin/bash

set -o nounset \
    -o errexit \
    -o verbose

# See what is in each keystore and truststore
for i in kafka1 kafka2 client schemaregistry restproxy connect controlcenter ksqlserver appSA badapp clientListen kafkaLagExporter
do
        echo "------------------------------- $i keystore -------------------------------"
	keytool -list -v -keystore kafka.$i.keystore.jks -storepass confluent | grep -e Alias -e Entry
        echo "------------------------------- $i truststore -------------------------------"
	keytool -list -v -keystore kafka.$i.truststore.jks -storepass confluent | grep -e Alias -e Entry
done
