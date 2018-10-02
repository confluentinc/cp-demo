#!/bin/bash

docker-compose exec connect curl -X DELETE --cert /etc/kafka/secrets/connect.certificate.pem --key /etc/kafka/secrets/connect.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt  https://connect:8083/connectors/elasticsearch
