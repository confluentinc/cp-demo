KAFKA_CLUSTER_ID=$(curl -s https://localhost:8091/v1/metadata/id --tlsv1.2 --cacert scripts/security/snakeoil-ca-1.crt | jq -r ".id")
