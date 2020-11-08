#!/bin/bash

#set -o nounset \
#    -o errexit \
#    -o verbose \
#    -o xtrace

# Cleanup files
rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12 *.log

# Generate CA key
openssl req -new -x509 -keyout snakeoil-ca-1.key -out snakeoil-ca-1.crt -days 365 -subj '/CN=ca1.test.confluentdemo.io/OU=TEST/O=CONFLUENT/L=PaloAlto/ST=Ca/C=US' -passin pass:confluent -passout pass:confluent

# we no longer generating a cert for ksqlDB Server - it shares a cert with Control Center
users=(kafka1 kafka2 client schemaregistry restproxy connect connectorSA control-center ksqlDBUser appSA badapp clientListen zookeeper mds)
echo "Creating certificates"
printf '%s\0' "${users[@]}" | xargs -0 -I{} -n1 -P15 sh -c './certs-create-per-user.sh "$1" > "certs-create-$1.log" 2>&1 && echo "Created certificates for $1"' -- {}
echo "Creating certificates completed"

# we no longer generating a cert for ksqlDB Server - it shares a cert with Control Center
cp kafka.control-center.keystore.jks kafka.ksqldb-server.keystore.jks
cp kafka.control-center.truststore.jks kafka.ksqldb-server.truststore.jks
