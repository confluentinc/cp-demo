#!/bin/bash

set -o nounset \
    -o errexit \
    -o verbose \
    -o xtrace

# Cleanup files
rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12

# Generate CA key
openssl req -new -x509 -keyout snakeoil-ca-1.key -out snakeoil-ca-1.crt -days 365 -subj '/CN=ca1.test.confluent.io/OU=TEST/O=CONFLUENT/L=PaloAlto/S=Ca/C=US' -passin pass:confluent -passout pass:confluent

for i in kafka1 kafka2 client schemaregistry
do
	echo $i
	# Create keystores
	keytool -genkey -noprompt \
				 -alias $i \
				 -dname "CN=$i,OU=TEST,O=CONFLUENT,L=PaloAlto,S=Ca,C=US" \
                                 -ext san=dns:$i \
				 -keystore kafka.$i.keystore.jks \
				 -keyalg RSA \
				 -storepass confluent \
				 -keypass confluent

	# Create CSR, sign the key and import back into keystore
	keytool -keystore kafka.$i.keystore.jks -alias $i -certreq -file $i.csr -storepass confluent -keypass confluent

	openssl x509 -req -CA snakeoil-ca-1.crt -CAkey snakeoil-ca-1.key -in $i.csr -out $i-ca1-signed.crt -days 9999 -CAcreateserial -passin pass:confluent

	keytool -noprompt -keystore kafka.$i.keystore.jks -alias CARoot -import -file snakeoil-ca-1.crt -storepass confluent -keypass confluent

	keytool -noprompt -keystore kafka.$i.keystore.jks -alias $i -import -file $i-ca1-signed.crt -storepass confluent -keypass confluent

	# Create truststore and import the CA cert.
	keytool -noprompt -keystore kafka.$i.truststore.jks -alias CARoot -import -file snakeoil-ca-1.crt -storepass confluent -keypass confluent

	# Create pem files and keys used for testing:
	#   openssl x509 -noout -modulus -in client.certificate.pem | openssl md5
	#   openssl rsa -noout -modulus -in client.key | openssl md5 
        #   openssl s_client -connect localhost:8082/subjects -cert client.certificate.pem -key client.key -tls1
	keytool -export -alias $i -file $i.der -keystore kafka.$i.keystore.jks -storepass confluent
	openssl x509 -inform der -in $i.der -out $i.certificate.pem
	keytool -importkeystore -srckeystore kafka.$i.keystore.jks -destkeystore $i.keystore.p12 -deststoretype PKCS12 -deststorepass confluent -srcstorepass confluent -noprompt
	openssl pkcs12 -in $i.keystore.p12 -nodes -nocerts -out $i.key -passin pass:confluent

  	echo "confluent" > ${i}_sslkey_creds
  	echo "confluent" > ${i}_keystore_creds
  	echo "confluent" > ${i}_truststore_creds
done
