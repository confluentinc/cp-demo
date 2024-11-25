.. _scripted-demo:

Scripted |cp| Demo
==================

The scripted |cp| demo (``cp-demo``) example builds a full |cp| deployment with an |ak-tm| event streaming
application that uses :ref:`ksqlDB <ksql_home>` and :ref:`Kafka Streams <kafka_streams>` for stream processing,
and secures all of the components end-to-end.
The tutorial includes a module that makes it a hybrid deployment that runs |cluster-linking| and Schema
Linking to copy data and schemas from a local on-premises |ak| cluster to |ccloud|, a fully-managed service
for |ak|.

Follow the accompanying guided tutorial to learn how |ak| and |ccloud| work
with |kconnect|, |sr-long|, |c3|, and |cluster-linking| with security enabled end-to-end.

.. include:: ../../includes/cp-cta.rst


Use case
--------

In this demo you build a |ak| event streaming application that processes real-time edits to real Wikipedia pages.
The following image shows the application topology:

.. figure:: images/cp-demo-overview-with-ccloud.svg
    :alt: image

The full event streaming platform based on |cp| consists of:

- Wikimedia's `EventStreams <https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams>`__ publishes a continuous stream of real-time edits happening to real wiki pages.
- A |ak| source connector `kafka-connect-sse <https://www.confluent.io/hub/cjmatta/kafka-connect-sse>`__ streams the server-sent events (SSE) from https://stream.wikimedia.org/v2/stream/recentchange, and a custom |kconnect| transform `kafka-connect-json-schema <https://www.confluent.io/hub/jcustenborder/kafka-connect-json-schema>`__
   extracts the JSON from these messages and then are written to a |ak| cluster.
- Data processing using :ref:`ksqlDB <ksql_home>` and a :ref:`Kafka Streams <kafka_streams>` application.
- A |ak| sink connector `kafka-connect-elasticsearch <https://www.confluent.io/hub/confluentinc/kafka-connect-elasticsearch>`__ streams the data out of |ak| and is materialized into `Elasticsearch <https://www.elastic.co/products/elasticsearch>`__ for analysis by `Kibana <https://www.elastic.co/products/kibana>`__.

All data in the Avro format, uses |sr-long|, and `Confluent Control Center
<https://www.confluent.io/product/control-center/>`__ manages and monitors the deployment.

Data pattern
------------

This table depicts the application's data pattern:

.. list-table:: List tables can have captions like this one.
    :header-rows: 1

    * - Components
      - Consumes from
      - Produces to
    * - SSE source connector
      - Wikipedia
      - ``wikipedia.parsed``
    * - ksqlDB
      - ``wikipedia.parsed``
      - |ksql-cloud| streams and tables
    * - |ak| Streams application
      - ``wikipedia.parsed``
      - ``wikipedia.parsed.count-by-domain``
    * - Elasticsearch sink connector
      - ``WIKIPEDIABOT`` (from |ksql-cloud|)
      - Elasticsearch/Kibana


How to use this tutorial
------------------------

You should follow the tutorial in order:

#. :ref:`cp-demo-on-prem-tutorial`: bring up the on-premises |ak| cluster and explore the different technical areas of |cp|.

#. :ref:`cp-demo-hybrid`: create a cluster link to copy data from a local on-premises |ak| cluster to |ccloud|, and use the Metrics API to monitor both.

#. :ref:`cp-demo-teardown`: troubleshoot issues with the demo and clean up your
      on-premises and |ccloud| environments.
