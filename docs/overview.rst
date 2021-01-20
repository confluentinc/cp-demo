Confluent Platform Demo (cp-demo)
=================================

This example builds a full |cp| deployment with an |ak-tm| event streaming application using `ksqlDB <https://ksqldb.io>`__ and `Kafka Streams <https://docs.confluent.io/platform/current/streams/index.html>`__ for stream processing, and all the components have security enabled end-to-end.
Follow the accompanying guided tutorial, broken down step-by-step, to learn how |ak| works all together with |kconnect|, |sr-long|, |c3|, |crep|, and security enabled end-to-end.
The tutorial includes a module to extend it into a hybrid deployment that runs |crep| to copy data from a local on-prem |ak| cluster to |ccloud|, a fully-managed service for |ak-tm|.

========
Overview
========

Use Case
--------

The use case is an |ak-tm| event streaming application that processes real-time edits to real Wikipedia pages.

.. figure:: images/cp-demo-overview.jpg
    :alt: image

The full event streaming platform based on |cp| is described as follows.
Wikimedia's `EventStreams <https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams>`__ publishes a continuous stream of real-time edits happening to real wiki pages.
A Kafka source connector `kafka-connect-sse <https://www.confluent.io/hub/cjmatta/kafka-connect-sse>`__ streams the server-sent events (SSE) from https://stream.wikimedia.org/v2/stream/recentchange, and a custom |kconnect| transform `kafka-connect-json-schema <https://www.confluent.io/hub/jcustenborder/kafka-connect-json-schema>`__ extracts the JSON from these messages and then are written to a |ak| cluster.
This example uses `ksqlDB <https://ksqldb.io>`__ and a :ref:`Kafka Streams <kafka_streams>` application for data processing.
Then a Kafka sink connector `kafka-connect-elasticsearch <https://www.confluent.io/hub/confluentinc/kafka-connect-elasticsearch>`__ streams the data out of Kafka and is materialized into `Elasticsearch <https://www.elastic.co/products/elasticsearch>`__ for analysis by `Kibana <https://www.elastic.co/products/kibana>`__.
|crep-full| is also copying messages from a topic to another topic in the same cluster.
All data is using |sr-long| and Avro, and `Confluent Control Center <https://www.confluent.io/product/control-center/>`__ is managing and monitoring the deployment.

Data Pattern
------------

Data pattern is as follows:

+-------------------------------------+--------------------------------+---------------------------------------+
| Components                          | Consumes From                  | Produces To                           |
+=====================================+================================+=======================================+
| SSE source connector                | Wikipedia                      | ``wikipedia.parsed``                  |
+-------------------------------------+--------------------------------+---------------------------------------+
| ksqlDB                              | ``wikipedia.parsed``           | ksqlDB streams and tables             |
+-------------------------------------+--------------------------------+---------------------------------------+
| Kafka Streams application           | ``wikipedia.parsed``           | ``wikipedia.parsed.count-by-domain``  |
+-------------------------------------+--------------------------------+---------------------------------------+
| Confluent Replicator                | ``wikipedia.parsed``           | ``wikipedia.parsed.replica``          |
+-------------------------------------+--------------------------------+---------------------------------------+
| Elasticsearch sink connector        | ``WIKIPEDIABOT`` (from ksqlDB) | Elasticsearch/Kibana                  |
+-------------------------------------+--------------------------------+---------------------------------------+

How to use this tutorial
------------------------

We suggest following the ``cp-demo`` tutorial in order:

#. :ref:`cp-demo-on-prem-tutorial`: bring up the on-prem |ak| cluster

#. :ref:`cp-demo-guide`: explore the different technical areas of |cp|

#. :ref:`cp-demo-hybrid`: run |crep| to copy data from a local on-prem |ak| cluster to |ccloud|, and use the Metrics API to monitor both

#. :ref:`cp-demo-teardown`: clean up your on-prem and |ccloud| environment
