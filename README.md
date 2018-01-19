**Table of Contents**

- [Overview](#overview)
- [Installation](docs/index.rst)
- [Start demo](docs/index.rst)
- [Playbook](docs/index.rst)
    * [Tour of Confluent Control Center](docs/index.rst)
    * [KSQL](docs/index.rst)
    * [Consumer rebalances](docs/index.rst)
    * [Slow consumers](docs/index.rst)
    * [Over consumption](docs/index.rst)
    * [Under consumption](docs/index.rst)
    * [Failed broker](docs/index.rst)
    * [Alerting](docs/index.rst)
    * [Replicator](docs/index.rst)
    * [Security](docs/index.rst)
- [Troubleshooting the demo](docs/index.rst)
- [Teardown](docs/index.rst)


## Overview

This demo shows users how to monitor Kafka streaming ETL deployments using [Confluent Control Center](http://docs.confluent.io/current/control-center/docs/index.html). All the components in the Confluent platform have security enabled end-to-end. Follow along with the playbook in this README and watch the video tutorials.

The use case is a stream processing on live edits to real Wikipedia pages. Wikimedia Foundation has IRC channels that publish edits happening to real wiki pages (e.g. #en.wikipedia, #en.wiktionary) in real time. Using [Kafka Connect](http://docs.confluent.io/current/connect/index.html), a Kafka source connector [kafka-connect-irc](https://github.com/cjmatta/kafka-connect-irc) streams raw messages from these IRC channels, and a custom Kafka Connect transform [kafka-connect-transform-wikiedit](https://github.com/cjmatta/kafka-connect-transform-wikiedit) transforms these messages and then the messages are written to a Kafka cluster. This demo uses [KSQL](https://github.com/confluentinc/ksql) for data enrichment, or you can optionally develop and run your own [Kafka Streams](http://docs.confluent.io/current/streams/index.html) application. Then a Kafka sink connector [kafka-connect-elasticsearch](http://docs.confluent.io/current/connect/connect-elasticsearch/docs/elasticsearch_connector.html) streams the data out of Kafka, applying another custom Kafka Connect transform called NullFilter. The data is materialized into [Elasticsearch](https://www.elastic.co/products/elasticsearch) for analysis by [Kibana](https://www.elastic.co/products/kibana).

![image](docs/images/drawing.png)

-------------------------------------------------------------

_Note_: this is a Docker environment and has all services running on one host. Do not use this demo in production. It is meant exclusively to easily demo the Confluent Platform. In production, Confluent Control Center should be deployed with a valid license and with its own dedicated metrics cluster, separate from the cluster with production traffic. Using a dedicated metrics cluster is more resilient because it continues to provide system health monitoring even if the production traffic cluster experiences issues.

-------------------------------------------------------------

Please follow the links in the Table of Contents above for instructions to install and run the demo, and follow along with the playbook.
