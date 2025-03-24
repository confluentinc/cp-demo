#!/bin/bash

SBCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${SBCDIR}/../helper/functions.sh
source ${SBCDIR}/../env.sh

docker-compose -f $SBCDIR/../../compose.yaml -f $SBCDIR/compose.yaml logs kafka1 kafka2 | grep "COMPLETED.*databalancer"
