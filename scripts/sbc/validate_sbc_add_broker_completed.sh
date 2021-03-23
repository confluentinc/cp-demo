#!/bin/bash

SBCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${SBCDIR}/../helper/functions.sh
source ${SBCDIR}/../env.sh

docker-compose -f $SBCDIR/../../docker-compose.yml -f $SBCDIR/docker-compose.yml logs kafka1 kafka2 | grep "COMPLETED.*databalancer"
