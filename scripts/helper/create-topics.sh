#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

topics=(appSA.config users \
        connectorSA_without_interceptors_ssl.config wikipedia.parsed \
        connectorSA_without_interceptors_ssl.config wikipedia.parsed.count-by-domain \
        connectorSA_without_interceptors_ssl.config wikipedia.failed \
        ksqlDBUser_without_interceptors_ssl.config WIKIPEDIABOT \
        ksqlDBUser_without_interceptors_ssl.config WIKIPEDIANOBOT \
        ksqlDBUser_without_interceptors_ssl.config EN_WIKIPEDIA_GT_1 \
        ksqlDBUser_without_interceptors_ssl.config EN_WIKIPEDIA_GT_1_COUNTS \
       )

printf '%s\0' "${topics[@]}" | xargs -0 -n2 -P15 sh -c 'echo "Creating topic $2 with principal $1";./create-topic.sh "$1" "$2";echo "Created topic $2";' sh
