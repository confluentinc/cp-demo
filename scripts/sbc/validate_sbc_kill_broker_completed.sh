#!/bin/bash

SBCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${SBCDIR}/../helper/functions.sh
source ${SBCDIR}/../env.sh

docker-compose -f $SBCDIR/../../docker-compose.yml -f $SBCDIR/docker-compose.yml logs kafka1 kafka2 | grep "BROKER_FAILURE.*execution finishes" || exit 1
(docker-compose -f $SBCDIR/../../docker-compose.yml -f $SBCDIR/docker-compose.yml exec kafka1 kafka-replica-status --bootstrap-server kafka1:9091 --admin.config /etc/kafka/secrets/client_sasl_plain.config --verbose || exit 1) | grep "IsInIsr: false" && exit 1
exit 0
