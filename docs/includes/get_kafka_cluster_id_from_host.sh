KAFKA_CLUSTER_ID=$(curl -s -k https://localhost:8091/v1/metadata/id --cert scripts/security/mds.certificate.pem --key scripts/security/mds.key --tlsv1.2 --cacert scripts/security/snakeoil-ca-1.crt | jq -r ".id")
