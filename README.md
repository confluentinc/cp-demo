# Kafka Event Streaming Applications

This demo and accompanying tutorial show users how to deploy an Apache Kafka® event streaming application using [ksqlDB](https://www.confluent.io/product/ksql/?utm_source=github&utm_medium=demo&utm_campaign=ch.cp-demo_type.community_content.cp-demo) and [Kafka Streams](https://docs.confluent.io/current/streams/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.cp-demo_type.community_content.cp-demo) for stream processing. All the components in the Confluent platform have security enabled end-to-end. Run the demo with the [tutorial](https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.cp-demo_type.community_content.cp-demo).

**Table of Contents**

- [Overview](#overview)
- [Documentation](#documentation)

## FF-1556 index/bulk query-string parameter support (this branch)

This branch contains additional configuration and Connect docker-container build to allow testing of Elasticsearch Connector PR https://github.com/confluentinc/kafka-connect-elasticsearch/pull/418 , which adds support for configuring query-string paramters to be sent with index and bulk Elasticsearch API requests.

In order to test this for a specific use-case, using Elasticsearch ingest pipelines, for example to allow a rounded-date-time-field based index-name, this also requires a patch and snapshot build of the Elasticsearch connector underlying Jest API client: https://github.com/searchbox-io/Jest/pull/679 .  This branch incorporates that patch into the connector build.

To test:

- I had trouble building the Elasticsearch connector without access to Confluent Artifactory - so you will need to copy-in your Maven `.m2/settings.xml` to same path in this repo (it is `.gitignore`-d)
- `export DOCKER_BUILDKIT=1` in the current shell
- Run demo as normal.  Use the Elasticsearch API, or Kibana, to see documents being created in the `wikipediabot` index.
- Review and run `scripts/elasticsearch/create_pipeline.sh` to create a processing pipeline named `/wikipediabot-createdat-monthlyindex`
- Review and run `scripts/connectors/update_elastic_sink_config_with_pipeline.sh`, which updates the Elasticsearch sink connector to add configuration property `"elasticsearch.index.param.pipeline": "wikipediabot-createdat-monthlyindex"`.
- Revisit Kibana and define an index pattern `wikipediabot-*`.  You should see records being indexed by a prefixed, rounded date-based name based on field `CREATEDAT`.

The existing version of Elasticsearch did not support `date_index_name` processors on a epoch-based date-time field, so this demo necessitated a rushed Elasticsearch/Kibana upgrade - you will find that the normal dashboards are not intact, but it is sufficient to check that documents appear in date-based prefixed indexes.

## Overview

The use case is a Kafka event streaming application for real-time edits to real Wikipedia pages.
Wikimedia Foundation has IRC channels that publish edits happening to real wiki pages (e.g. `#en.wikipedia`, `#en.wiktionary`) in real time.
Using Kafka Connect, a Kafka source connector `kafka-connect-irc` streams raw messages from these IRC channels, and a custom Kafka Connect transform `kafka-connect-transform-wikiedit` transforms these messages and then the messages are written to a Kafka cluster.
This demo uses ksqlDB and a Kafka Streams application for data processing.
Then a Kafka sink connector `kafka-connect-elasticsearch`streams the data out of Kafka, and the data is materialized into Elasticsearch for analysis by Kibana.
Confluent Replicator  is also copying messages from a topic to another topic in the same cluster.
All data is using Confluent Schema Registry and Avro.
Confluent Control Center is managing and monitoring the deployment.

![image](docs/images/cp-demo-overview.jpg)

## Documentation

You can find the documentation for running this demo and its accompanying tutorial at [https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html](https://docs.confluent.io/current/tutorials/cp-demo/docs/index.html?utm_source=github&utm_medium=demo&utm_campaign=ch.cp-demo_type.community_content.cp-demo).

# Additional Examples

For additional examples that showcase streaming applications within an event streaming platform, please refer to the [examples GitHub repository](https://github.com/confluentinc/examples).
