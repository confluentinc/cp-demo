#!/bin/bash

/usr/local/bin/dub template /etc/confluent/docker/kafka.properties.template /etc/kafka/kafka-streams.properties
echo $JAVA_OPTS
echo $KAFKA_OPTS
set
java $JAVA_OPTS $KAFKA_OPTS -cp /app/resources:/app/classes:/app/libs/* io.confluent.demos.common.wiki.WikipediaActivityMonitor "/etc/kafka/kafka-streams.properties"

