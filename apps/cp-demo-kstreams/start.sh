#!/bin/bash

/usr/local/bin/dub template /etc/confluent/docker/kafka.properties.template /etc/kafka/kafka-streams.properties
java $JAVA_OPTS $KAFKA_OPTS -jar /app/cp-demo-kstreams.jar /etc/kafka/kafka-streams.properties

