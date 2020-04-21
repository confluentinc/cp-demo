.. _cp-demo:

Confluent Platform Demo (cp-demo)
=================================

This demo builds a full |cp| deployment with a Kafka event streaming application using `KSQL <https://www.confluent.io/product/ksql/>`__ and `Kafka Streams <https://docs.confluent.io/current/streams/index.html>`__ for stream processing.
Follow the accompanying guided tutorial that steps through the demo so that you can learn how it all works together.
All the components in the Confluent platform have security enabled end-to-end.


========
Overview
========

The use case is a Kafka event streaming application for real-time edits to real Wikipedia pages.
Wikimedia Foundation has IRC channels that publish edits happening to real wiki pages (e.g. ``#en.wikipedia``, ``#en.wiktionary``) in real time.
Using `Kafka Connect <http://docs.confluent.io/current/connect/index.html>`__, a Kafka source connector `kafka-connect-irc <https://github.com/cjmatta/kafka-connect-irc>`__ streams raw messages from these IRC channels, and a custom Kafka Connect transform `kafka-connect-transform-wikiedit <https://github.com/cjmatta/kafka-connect-transform-wikiedit>`__ transforms these messages and then the messages are written to a Kafka cluster.
This demo uses `KSQL <https://www.confluent.io/product/ksql/>`__ and a `Kafka Streams <http://docs.confluent.io/current/streams/index.html>`__ application for data processing.
Then a Kafka sink connector `kafka-connect-elasticsearch <http://docs.confluent.io/current/connect/connect-elasticsearch/docs/elasticsearch_connector.html>`__ streams the data out of Kafka, and the data is materialized into `Elasticsearch <https://www.elastic.co/products/elasticsearch>`__ for analysis by `Kibana <https://www.elastic.co/products/kibana>`__.
|crep-full| is also copying messages from a topic to another topic in the same cluster.
All data is using |sr-long| and Avro.
`Confluent Control Center <https://www.confluent.io/product/control-center/>`__ is managing and monitoring the deployment.


.. figure:: images/cp-demo-overview.jpg
    :alt: image


.. note:: This is a Docker environment and has all services running on one host. Do not use this demo in production. It is meant exclusively to easily demo the |CP|. In production, |c3| should be deployed with a valid license and with its own dedicated metrics cluster, separate from the cluster with production traffic. Using a dedicated metrics cluster is more resilient because it continues to provide system health monitoring even if the production traffic cluster experiences issues.


Data pattern is as follows:

+-------------------------------------+------------------------------+---------------------------------------+
| Components                          | Consumes From                | Produces To                           |
+=====================================+==============================+=======================================+
| IRC source connector                | Wikipedia                    | ``wikipedia.parsed``                  |
+-------------------------------------+------------------------------+---------------------------------------+
| KSQL                                | ``wikipedia.parsed``         | KSQL streams and tables               |
+-------------------------------------+------------------------------+---------------------------------------+
| Kafka Streams application           | ``wikipedia.parsed``         | ``wikipedia.parsed.count-by-channel`` |
+-------------------------------------+------------------------------+---------------------------------------+
| Confluent Replicator                | ``wikipedia.parsed``         | ``wikipedia.parsed.replica``          |
+-------------------------------------+------------------------------+---------------------------------------+
| Elasticsearch sink connector        | ``WIKIPEDIABOT`` (from KSQL) | Elasticsearch/Kibana                  |
+-------------------------------------+------------------------------+---------------------------------------+


========
Run Demo
========

Demo validated with:

-  Docker version 17.06.1-ce
-  Docker Compose version 1.14.0 with Docker Compose file format 2.3
-  Java version 1.8.0_92
-  MacOS 10.15.3 (note for `Ubuntu environments <https://github.com/confluentinc/cp-demo/issues/53>`__)
-  OpenSSL 1.1.1d
-  Python 3.7.6
-  git
-  jq

.. note:: If you prefer other non-Docker demos, please go to `confluentinc/examples GitHub repository <https://github.com/confluentinc/examples>`__.


#. Clone the `confluentinc/cp-demo GitHub repository <https://github.com/confluentinc/cp-demo>`__:

   .. sourcecode:: bash

       git clone https://github.com/confluentinc/cp-demo

#. In Docker's advanced `settings <https://docs.docker.com/docker-for-mac/#advanced>`__, increase the memory dedicated to Docker to at least 8GB (default is 2GB).

#. From the ``cp-demo`` directory, start the entire demo by running a single command that generates the keys and certificates, brings up the Docker containers, and configures and validates the environment. This will take approximately 7 minutes to complete.

   .. sourcecode:: bash

        ./scripts/start.sh

#. Use Google Chrome to view the |c3| GUI at http://localhost:9021. For this tutorial, log in as ``superUser`` and password ``superUser``, which has super user access to the cluster. You may also log in as :devx-cp-demo:`other users|scripts//security/ldap_users` to learn how each user's view changes depending on their permissions.

5. To see the end of the entire pipeline, view the Kibana dashboard at http://localhost:5601/app/kibana#/dashboard/Wikipedia


===============
Guided Tutorial
===============

Brokers 
-------

#. Select the cluster named "Kafka Raleigh".

   .. figure:: images/cluster_raleigh.png

#. Click on "Brokers".

#. View the status of the Brokers in the cluster:

   .. figure:: images/landing_page.png

#. Click through on Production or Consumption to view: Production and Consumption metrics, Broker uptime, Partitions: online, under replicated, total replicas, out of sync replicas, Disk utilization, System: network pool usage, request pool usage.

   .. figure:: images/broker_metrics.png




Topics
------

#. |c3| can manage topics in a Kafka cluster. Click on "Topics".

#. Scroll down and click on the topic ``wikipedia.parsed``.

   .. figure:: images/topic_list_wikipedia.png
         :alt: image

#. View an overview of this topic:

   - Throughput
   - Partition replication status

   .. figure:: images/topic_actions.png
      :alt: image

#. View which brokers are leaders for which partitions and where all partitions reside.

   .. figure:: images/topic_info.png
      :alt: image

#. Inspect messages for this topic, in real-time.

   .. figure:: images/topic_inspect.png
      :alt: image

#. View the schema for this topic. For ``wikipedia.parsed``, the topic value is using a Schema registered with |sr| (the topic key is just a string).

   .. figure:: images/topic_schema.png
      :alt: image

#. View configuration settings for this topic.

   .. figure:: images/topic_settings.png
      :alt: image

#. Return to "All Topics", click on ``wikipedia.parsed.count-by-channel`` to view the output topic from the Kafka Streams application.

   .. figure:: images/count-topic-view.png
      :alt: image

#. Return to the ``All topics`` view and click the **+ Add a topic** button on the top right to create a new topic in your Kafka cluster. You can also view and edit settings of Kafka topics in the cluster. Read more on |c3| `topic management <https://docs.confluent.io/current/control-center/docs/topics.html>`__.

   .. figure:: images/create_topic.png
         :alt: image

#.  Dataflow: you can derive which producers are writing to which topics and which consumers are reading from which topics.
    When Confluent Monitoring Interceptors are configured on Kafka clients, they write metadata to a topic named ``_confluent-monitoring``.
    Kafka clients include any application that uses the Apache Kafka client API to connect to Kafka brokers, such as
    custom client code or any service that has embedded producers or consumers, such as Kafka Connect, KSQL, or a Kafka Streams application.
    |c3| uses that topic to ensure that all messages are delivered and to provide statistics on throughput and latency
    performance. From that same topic, you can also derive which producers are writing to which topics and which consumers
    are reading from which topics, and an example script is provided with the repo (note: this is for demo purposes
    only, not suitable for production). The command is:

    .. sourcecode:: bash

      ./scripts/app/map_topics_clients.py

    Your output should resemble:

    .. sourcecode:: bash

      Reading topic _confluent-monitoring for 60 seconds...please wait

      EN_WIKIPEDIA_GT_1
        producers
          _confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4-31d073dc-a865-4767-b591-a69fa3ed2609-StreamThread-3-producer
          _confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4-31d073dc-a865-4767-b591-a69fa3ed2609-StreamThread-4-producer
        consumers
          _confluent-ksql-ksql-clusterquery_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_6
      
      EN_WIKIPEDIA_GT_1_COUNTS
        producers
          _confluent-ksql-ksql-clusterquery_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_6-f1aab97c-0d40-4d9c-b902-8b70ee20a7af-StreamThread-1-producer
          _confluent-ksql-ksql-clusterquery_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_6-f1aab97c-0d40-4d9c-b902-8b70ee20a7af-StreamThread-2-producer
      
      WIKIPEDIABOT
        producers
          _confluent-ksql-ksql-clusterquery_CSAS_WIKIPEDIABOT_3-73856d55-a996-4267-ad43-a291e8473eb7-StreamThread-1-producer
          _confluent-ksql-ksql-clusterquery_CSAS_WIKIPEDIABOT_3-73856d55-a996-4267-ad43-a291e8473eb7-StreamThread-2-producer
        consumers
          connect-elasticsearch-ksql
      
      WIKIPEDIANOBOT
        producers
          _confluent-ksql-ksql-clusterquery_CSAS_WIKIPEDIANOBOT_2-7845e732-6d79-4576-98bf-748e2e8401c3-StreamThread-1-producer
          _confluent-ksql-ksql-clusterquery_CSAS_WIKIPEDIANOBOT_2-7845e732-6d79-4576-98bf-748e2e8401c3-StreamThread-2-producer
      
      _confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4-Aggregate-aggregate-changelog
        producers
          _confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4-31d073dc-a865-4767-b591-a69fa3ed2609-StreamThread-3-producer
          _confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4-31d073dc-a865-4767-b591-a69fa3ed2609-StreamThread-4-producer
      
      _confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4-Aggregate-groupby-repartition
        producers
          _confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4-31d073dc-a865-4767-b591-a69fa3ed2609-StreamThread-1-producer
        consumers
          _confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4
      
      wikipedia-activity-monitor-KSTREAM-AGGREGATE-STATE-STORE-0000000002-changelog
        producers
          wikipedia-activity-monitor-StreamThread-1-producer
      
      wikipedia.parsed
        producers
          connect-worker-producer
        consumers
          _confluent-ksql-ksql-clusterquery_CSAS_WIKIPEDIABOT_3
          _confluent-ksql-ksql-clusterquery_CSAS_WIKIPEDIANOBOT_2
          _confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4
          connect-replicator
          wikipedia-activity-monitor
      
      wikipedia.parsed.count-by-channel
        producers
          wikipedia-activity-monitor-StreamThread-1-producer
      
      wikipedia.parsed.replica
        producers
          connect-worker-producer
      

Connect
-------

#. |c3| uses the Kafka Connect API to manage multiple `connect clusters <https://docs.confluent.io/current/control-center/docs/connect.html>`__.  Click on "Connect".

#. Select ``connect1``, the name of the cluster of |kconnect| workers.

   .. figure:: images/connect_default.png

#. Verify the connectors running in this demo:

   - source connector ``wikipedia-irc`` view the demo's IRC source connector :devx-cp-demo:`configuration file|scripts/connectors/submit_wikipedia_irc_config.sh`.
   - source connector ``replicate-topic``: view the demo's |crep| connector :devx-cp-demo:`configuration file|scripts/connectors/submit_replicator_config.sh`.
   - sink connector ``elasticsearch-ksql`` consuming from the Kafka topic ``WIKIPEDIABOT``: view the demo's Elasticsearch sink connector :devx-cp-demo:`configuration file|scripts/connectors/submit_elastic_sink_config.sh`.

   .. figure:: images/connector_list.png

#. Click any connector name to view or modify any details of the connector configuration and custom transforms.

   .. figure:: images/connect_replicator_settings.png


.. _ksql-demo-3:

KSQL
----

In this demo, KSQL is authenticated and authorized to connect to the secured Kafka cluster, and it is already running queries as defined in the :devx-cp-demo:`KSQL command file|scripts/ksql/ksqlcommands` .

#. In the navigation bar, click **KSQL**.

#. From the list of KSQL applications, select ``ksql1``.

   .. figure:: images/ksql_link.png
      :alt: image

#. Alternatively, run KSQL CLI to get to the KSQL CLI prompt.

   .. sourcecode:: bash

        docker-compose exec ksql-cli bash -c 'ksql -u ksqlUser -p ksqlUser http://ksql-server:8088'

#. View the existing KSQL streams. (If you are using the KSQL CLI, at the ``ksql>`` prompt type ``SHOW STREAMS;``)

   .. figure:: images/ksql_streams_list.png
      :alt: image

#. Click on ``WIKIPEDIA`` to describe the schema (fields or columns) of an existing KSQL stream. (If you are using the KSQL CLI, at the ``ksql>`` prompt type ``DESCRIBE WIKIPEDIA;``)

   .. figure:: images/wikipedia_describe.png
      :alt: image

#. View the existing KSQL tables. (If you are using the KSQL CLI, at the ``ksql>`` prompt type ``SHOW TABLES;``).

   .. figure:: images/ksql_tables_list.png
      :alt: image

#. View the existing KSQL queries, which are continuously running. (If you are using the KSQL CLI, at the ``ksql>`` prompt type ``SHOW QUERIES;``).

   .. figure:: images/ksql_queries_list.png
      :alt: image

#. View messages from different KSQL streams and tables. Click on your stream of choice and select **Query** to open the Query Editor. The editor shows a pre-populated query, like ``select * from WIKIPEDIA EMIT CHANGES;``, and it shows results for newly arriving data.

   .. figure:: images/ksql_query_topic.png
      :alt: image

#. Click **KSQL Editor** and run the ``SHOW PROPERTIES;`` statement. You can see the configured KSQL server properties and check these values with the :devx-cp-demo:`docker-compose.yml|docker-compose.yml` file.

   .. figure:: images/ksql_properties.png
      :alt: image

#. This demo creates two streams ``EN_WIKIPEDIA_GT_1`` and ``EN_WIKIPEDIA_GT_1_COUNTS``, and the reason is to demonstrate how KSQL windows work. ``EN_WIKIPEDIA_GT_1`` counts occurences with a tumbling window, and for a given key it writes a `null` into the table on the first seen message.  The underlying Kafka topic for ``EN_WIKIPEDIA_GT_1`` does not filter out those nulls, but since we want to send downstream just the counts greater than one, there is a separate Kafka topic for ````EN_WIKIPEDIA_GT_1_COUNTS`` which does filter out those nulls (e.g., the query has a clause ``where ROWTIME is not null``).  From the bash prompt, view those underlying Kafka topics.

- View messages in the topic ``EN_WIKIPEDIA_GT_1`` (jump to offset 0/partition 0), and notice the nulls:

  .. figure:: images/messages_in_EN_WIKIPEDIA_GT_1.png
     :alt: image

- For comparison, view messages in the topic ``EN_WIKIPEDIA_GT_1_COUNTS`` (jump to offset 0/partition 0), and notice no nulls:

  .. figure:: images/messages_in_EN_WIKIPEDIA_GT_1_COUNTS.png
     :alt: image

11. The `KSQL processing log <https://docs.confluent.io/current/ksql/docs/developer-guide/processing-log.html>`__ captures per-record errors during processing to help developers debug their KSQL queries. In this demo, the processing log uses mutual TLS (mTLS) authentication, as configured in the custom :devx-cp-demo:`log4j properties file|scripts/helper/log4j-secure.properties`, to write entries into a Kafka topic. To see it in action, in the KSQL editor run the following query for 20 seconds:

.. sourcecode:: bash

      SELECT SPLIT(wikipage, 'foobar')[2] FROM wikipedia EMIT CHANGES;

No records should be returned from this query. Since the field ``wikipage`` in the original stream ``wikipedia`` cannot be split in this way, KSQL writes these errors into the processing log for each record. View the processing log topic ``ksql-clusterksql_processing_log`` with topic inspection (jump to offset 0/partition 0) or the corresponding KSQL stream ``KSQL_PROCESSING_LOG`` with the KSQL editor (set ``auto.offset.reset=earliest``).

.. sourcecode:: bash

      SELECT * FROM KSQL_PROCESSING_LOG EMIT CHANGES;



Consumers
---------

#. |c3| enables you to monitor consumer lag and throughput performance. Consumer lag is the topic's high water mark (latest offset for the topic that has been written) minus the current consumer offset (latest offset read for that topic by that consumer group). Keep in mind the topic's write rate and consumer group's read rate when you consider the significance the consumer lag's size. Click on "Consumers".

#. Consumer lag is available on a `per-consumer basis <https://docs.confluent.io/current/control-center/consumers.html#view-consumer-lag-details-for-a-consumer-group>`__, including embedded consumers in sink connectors (e.g., ``connect-replicator`` and ``connect-elasticsearch-ksql``), KSQL queries (e.g., consumer groups whose names start with ``_confluent-ksql-default_query_``), console consumers (e.g., ``WIKIPEDIANOBOT-consumer``), etc.  Consumer lag is also available on a `per-topic basis <https://docs.confluent.io/current/control-center/topics/view.html#view-consumer-lag-for-a-topic>`__.

   .. figure:: images/consumer_group_list.png
      :alt: image

#. View consumer lag for the persistent KSQL "Create Stream As Select" query ``CSAS_WIKIPEDIABOT``, which is displayed as ``_confluent-ksql-ksql-clusterquery_CSAS_WIKIPEDIABOT_3`` in the consumer group list.

   .. figure:: images/ksql_query_CSAS_WIKIPEDIABOT_consumer_lag.png
      :alt: image

#. View consumer lag for the Kafka Streams application under the consumer group id ``wikipedia-activity-monitor``. This application is run by the `cnfldemos/cp-demo-kstreams <https://hub.docker.com/r/cnfldemos/cp-demo-kstreams>`__ Docker container (application `source code <https://github.com/confluentinc/demos-common/blob/master/src/main/java/io/confluent/demos/common/wiki/WikipediaActivityMonitor.java>`__).

   .. figure:: images/activity-monitor-consumer.png
      :alt: image

#. Consumption metrics are available on a `per-consumer basis <https://docs.confluent.io/current/control-center/consumers.html#view-consumption-details-for-a-consumer-group>`__. These consumption charts are only populated if `Confluent Monitoring Interceptors <https://docs.confluent.io/current/control-center/installation/clients.html>`__ are configured, as they are in this demo. You can view ``% messages consumed`` and ``end-to-end latency``.  View consumption metrics for the persistent KSQL "Create Stream As Select" query ``CSAS_WIKIPEDIABOT``, which is displayed as ``_confluent-ksql-default_query_CSAS_WIKIPEDIABOT_0`` in the consumer group list.

   .. figure:: images/ksql_query_CSAS_WIKIPEDIABOT_consumption.png
      :alt: image

#. |c3| shows which consumers in a consumer group are consuming from which partitions and on which brokers those partitions reside.  |c3| updates as consumer rebalances occur in a consumer group.  Start consuming from topic ``wikipedia.parsed`` with a new consumer group ``app`` with one consumer ``consumer_app_1``. It runs in the background.

   .. sourcecode:: bash

          ./scripts/app/start_consumer_app.sh 1

#. Let this consumer group run for 2 minutes until |c3|
   shows the consumer group ``app`` with steady consumption.
   This consumer group ``app`` has a single consumer ``consumer_app_1`` consuming all of the partitions in the topic ``wikipedia.parsed``. 

   .. figure:: images/consumer_start_one.png
      :alt: image

#. Add a second consumer ``consumer_app_2`` to the existing consumer
   group ``app``.

   .. sourcecode:: bash

          ./scripts/app/start_consumer_app.sh 2

#. Let this consumer group run for 2 minutes until |c3|
    shows the consumer group ``app`` with steady consumption.
    Notice that the consumers ``consumer_app_1`` and ``consumer_app_2``
    now share consumption of the partitions in the topic
    ``wikipedia.parsed``.

    .. figure:: images/consumer_start_two.png
      :alt: image

#. From the **Brokers -> Production** view, click on a point in the Request latency line graph to view a breakdown of latencies through the entire `request lifecycle <https://docs.confluent.io/current/control-center/docs/systemhealth.html>`__.

    .. figure:: images/slow_consumer_produce_latency_breakdown.png
       :alt: image


Replicator
----------

Confluent Replicator copies data from a source Kafka cluster to a
destination Kafka cluster. The source and destination clusters are
typically different clusters, but in this demo, Replicator is doing
intra-cluster replication, *i.e.*, the source and destination Kafka
clusters are the same. As with the rest of the components in the
solution, Confluent Replicator is also configured with security.

#. View Replicator status and throughput in a dedicated view in |c3|.

   .. figure:: images/replicator_c3_view.png
      :alt: image

#. **Consumers**: monitor throughput and latency of Confluent Replicator.
   Replicator is a Kafka Connect source connector and has a corresponding consumer group ``connect-replicator``.

   .. figure:: images/replicator_consumer_group_list.png
      :alt: image

#. View Replicator Consumer Lag.

   .. figure:: images/replicator_consumer_lag.png
      :alt: image

#. View Replicator Consumption metrics.

   .. figure:: images/replicator_consumption.png
      :alt: image

#. **Connect**: pause the |crep| connector in **Settings**
   by pressing the pause icon in the top right and wait for 10 seconds until it takes effect.  This will stop
   consumption for the related consumer group.

   .. figure:: images/pause_connector_replicator.png
      :alt: image

#. Observe that the ``connect-replicator`` consumer group has stopped
   consumption.

   .. figure:: images/replicator_stopped.png

#. Restart the Replicator connector.

#. Observe that the ``connect-replicator`` consumer group has resumed consumption. Notice several things:

   * Even though the consumer group `connect-replicator` was not running for some of this time, all messages are shown as delivered. This is because all bars are time windows relative to produce timestamp.
   * The latency peaks and then gradually decreases, because this is also relative to the produce timestamp.

#. Next step: Learn more about |crep| with the :ref:`Replicator Tutorial <replicator>`.


Security
--------

Because the cluster has security features enabled, clients need to communicate to the right broker port and provide the appropriate credentials depending on the listener.
This section explains the broker listeners and how to use them.

All the components in this demo are enabled with many `security
features <https://docs.confluent.io/current/security.html>`__:

-  :ref:`Metadata Service (MDS) <rbac-mds-config>` which is the central authority for authentication and authorization. It is configured with the Confluent Server Authorizer and talks to LDAP to authenticate clients.
-  `SSL <https://docs.confluent.io/current/kafka/authentication_ssl.html>`__ for encryption and mTLS, except for |zk| which does not support TLS. The demo :devx-cp-demo:`automatically generates|scripts/security/certs-create.sh` SSL certificates and creates keystores, truststores, and secures them with a password. 
-  :ref:`Role-Based Access Control (RBAC) <rbac-overview>` for authorization. If a resource has no associated ACLs, then users are not allowed to access the resource, except super users.
-  |zk| is configured for `SASL/DIGEST-MD5 <https://docs.confluent.io/current/kafka/authentication_sasl_plain.html#zookeeper>`__.
-  `HTTPS for Control Center <https://docs.confluent.io/current/control-center/docs/installation/configuration.html#https-settings>`__.
-  `HTTPS for Schema Registry <https://docs.confluent.io/current/schema-registry/docs/security.html>`__.
-  `HTTPS for Connect <https://docs.confluent.io/current/connect/security.html#configuring-the-kconnect-rest-api-for-http-or-https>`__.

.. note::
    This demo showcases a secure |CP| for educational purposes and is not meant to be complete best practices. There are certain differences between what is shown in the demo and what you should do in production:

    * Authorize users only for operations that they need, instead of making all of them super users
    * If the ``PLAINTEXT`` security protocol is used, these ``ANONYMOUS`` usernames should not be configured as super users
    * Consider not even opening the ``PLAINTEXT`` port if ``SSL`` or ``SASL_SSL`` are configured

There is an OpenLDAP server running in the demo, and each Kafka broker in the demo is configured with MDS and can talk to LDAP so that it can authenticate clients and Confluent Platform services and clients.

Each broker has five listener ports:

+---------------+----------------+--------------------------------------------------------------------+--------+--------+
| Name          | Protocol       | In this demo, used for ...                                         | kafka1 | kafka2 |
+===============+================+====================================================================+========+========+
| N/A           | MDS            | Authorization via RBAC                                             | 8091   | 8092   |
+---------------+----------------+--------------------------------------------------------------------+--------+--------+
| INTERNAL      | SASL_PLAINTEXT | CP Kafka clients (e.g. Confluent Metrics Reporter), SASL_PLAINTEXT | 9091   | 9092   |
+---------------+----------------+--------------------------------------------------------------------+--------+--------+
| TOKEN         | SASL_SSL       | |cp| service (e.g. |sr|) when they need to use impersonation       | 10091  | 10092  |
+---------------+----------------+--------------------------------------------------------------------+--------+--------+
| SSL           | SSL            | End clients, (e.g. `stream-demo`), with SSL no SASL                | 11091  | 11092  |
+---------------+----------------+--------------------------------------------------------------------+--------+--------+
| CLEAR         | PLAINTEXT      | No security, available as a backdoor; for demo and learning only   | 12091  | 12092  |
+---------------+----------------+--------------------------------------------------------------------+--------+--------+

End clients (non-CP clients):

- Authenticate using mTLS via the broker SSL listener.
- If they are also using |sr|, authenticate to Schema Registry via LDAP.
- If they are also using Confluent Monitoring interceptors, authenticate using mTLS via the broker SSL listener.
- Should never use the TOKEN listener which is meant only for internal communication between Confluent components.
- See :devx-cp-demo:`client configuration|env_files/streams-demo.env/` used in the demo by the ``streams-demo`` container running the Kafka Streams application ``wikipedia-activity-monitor``.

#. Verify the ports on which the Kafka brokers are listening with the
   following command, and they should match the table shown below:

   .. sourcecode:: bash

          docker-compose logs kafka1 | grep "Registered broker 1"
          docker-compose logs kafka2 | grep "Registered broker 2"

#. For demo only: Communicate with brokers via the PLAINTEXT port, client configurations are required

   .. sourcecode:: bash

           # CLEAR/PLAINTEXT port
           docker-compose exec kafka1 kafka-consumer-groups --list --bootstrap-server kafka1:12091

#. End clients: Communicate with brokers via the SSL port, and SSL parameters configured via the ``--command-config`` argument for command line tools or ``--consumer.config`` for kafka-console-consumer.

   .. sourcecode:: bash

           # SSL/SSL port
           docker-compose exec kafka1 kafka-consumer-groups --list --bootstrap-server kafka1:11091 \
               --command-config /etc/kafka/secrets/client_without_interceptors_ssl.config

#. If a client tries to communicate with brokers via the SSL port but does not specify the SSL parameters, it will fail

   .. sourcecode:: bash

           # SSL/SSL port
           docker-compose exec kafka1 kafka-consumer-groups --list --bootstrap-server kafka1:11091

   Your output should resemble:

   .. sourcecode:: bash

           ERROR Uncaught exception in thread 'kafka-admin-client-thread | adminclient-1': (org.apache.kafka.common.utils.KafkaThread)
           java.lang.OutOfMemoryError: Java heap space
           ...

#. Communicate with brokers via the SASL_PLAINTEXT port, and SASL_PLAINTEXT parameters configured via the ``--command-config`` argument for command line tools or ``--consumer.config`` for kafka-console-consumer.

   .. sourcecode:: bash

           # INTERNAL/SASL_PLAIN port
           docker-compose exec kafka1 kafka-consumer-groups --list --bootstrap-server kafka1:9091 \
               --command-config /etc/kafka/secrets/client_sasl_plain.config

#. Verify which users are configured to be super users.

   .. sourcecode:: bash

         docker-compose logs kafka1 | grep SUPER_USERS

   Your output should resemble the following. Notice this authorizes each service name which authenticates as itself,
   as well as the unauthenticated ``PLAINTEXT`` which authenticates as ``ANONYMOUS`` (for demo purposes only):

   .. sourcecode:: bash

         KAFKA_SUPER_USERS=User:admin;User:mds;User:superUser;User:ANONYMOUS

#. Verify that LDAP user ``appSA`` (which is not a super user) can consume messages from topic ``wikipedia.parsed``.  Notice that it is configured to authenticate to brokers with mTLS and authenticate to Schema Registry with LDAP.

   .. sourcecode:: bash

         docker-compose exec connect kafka-avro-console-consumer --bootstrap-server kafka1:11091,kafka2:11092 \
           --consumer-property security.protocol=SSL \
           --consumer-property ssl.truststore.location=/etc/kafka/secrets/kafka.appSA.truststore.jks \
           --consumer-property ssl.truststore.password=confluent \
           --consumer-property ssl.keystore.location=/etc/kafka/secrets/kafka.appSA.keystore.jks \
           --consumer-property ssl.keystore.password=confluent \
           --consumer-property ssl.key.password=confluent \
           --property schema.registry.url=https://schemaregistry:8085 \
           --property schema.registry.ssl.truststore.location=/etc/kafka/secrets/kafka.appSA.truststore.jks \
           --property schema.registry.ssl.truststore.password=confluent \
           --property basic.auth.credentials.source=USER_INFO \
           --property schema.registry.basic.auth.user.info=appSA:appSA \
           --group wikipedia.test \
           --topic wikipedia.parsed \
           --max-messages 5

#. Verify that LDAP user ``badapp`` cannot consume messages from topic ``wikipedia.parsed``.

   .. sourcecode:: bash

         docker-compose exec connect kafka-avro-console-consumer --bootstrap-server kafka1:11091,kafka2:11092 \
           --consumer-property security.protocol=SSL \
           --consumer-property ssl.truststore.location=/etc/kafka/secrets/kafka.badapp.truststore.jks \
           --consumer-property ssl.truststore.password=confluent \
           --consumer-property ssl.keystore.location=/etc/kafka/secrets/kafka.badapp.keystore.jks \
           --consumer-property ssl.keystore.password=confluent \
           --consumer-property ssl.key.password=confluent \
           --property schema.registry.url=https://schemaregistry:8085 \
           --property schema.registry.ssl.truststore.location=/etc/kafka/secrets/kafka.badapp.truststore.jks \
           --property schema.registry.ssl.truststore.password=confluent \
           --property basic.auth.credentials.source=USER_INFO \
           --property schema.registry.basic.auth.user.info=badapp:badapp \
           --group wikipedia.test \
           --topic wikipedia.parsed \
           --max-messages 5

   Your output should resemble:

   .. sourcecode:: bash

      ERROR [Consumer clientId=consumer-wikipedia.test-1, groupId=wikipedia.test] Topic authorization failed for topics [wikipedia.parsed]
      org.apache.kafka.common.errors.TopicAuthorizationException: Not authorized to access topics: [wikipedia.parsed]

#. Add a role binding that permits ``badapp`` client to consume from topic ``wikipedia.parsed`` and its related subject in |sr|.

   .. sourcecode:: bash

      # First get the KAFKA_CLUSTER_ID
      KAFKA_CLUSTER_ID=$(docker-compose exec zookeeper zookeeper-shell zookeeper:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)

      # Then create the role binding for the topic ``wikipedia.parsed``
      docker-compose exec tools bash -c "confluent iam rolebinding create \
          --principal User:badapp \
          --role ResourceOwner \
          --resource Topic:wikipedia.parsed \
          --kafka-cluster-id $KAFKA_CLUSTER_ID"

      # Then create the role binding for the group ``wikipedia.test``
      docker-compose exec tools bash -c "confluent iam rolebinding create \
          --principal User:badapp \
          --role ResourceOwner \
          --resource Group:wikipedia.test \
          --kafka-cluster-id $KAFKA_CLUSTER_ID"

      # Then create the role binding for the subject ``wikipedia.parsed-value``, i.e., the topic-value (versus the topic-key)
      docker-compose exec tools bash -c "confluent iam rolebinding create \
          --principal User:badapp \
          --role ResourceOwner \
          --resource Subject:wikipedia.parsed-value \
          --kafka-cluster-id $KAFKA_CLUSTER_ID \
          --schema-registry-cluster-id schema-registry"

#. Verify that LDAP user ``badapp`` now can consume messages from topic ``wikipedia.parsed``.

   .. sourcecode:: bash

         docker-compose exec connect kafka-avro-console-consumer --bootstrap-server kafka1:11091,kafka2:11092 \
           --consumer-property security.protocol=SSL \
           --consumer-property ssl.truststore.location=/etc/kafka/secrets/kafka.badapp.truststore.jks \
           --consumer-property ssl.truststore.password=confluent \
           --consumer-property ssl.keystore.location=/etc/kafka/secrets/kafka.badapp.keystore.jks \
           --consumer-property ssl.keystore.password=confluent \
           --consumer-property ssl.key.password=confluent \
           --property schema.registry.url=https://schemaregistry:8085 \
           --property schema.registry.ssl.truststore.location=/etc/kafka/secrets/kafka.badapp.truststore.jks \
           --property schema.registry.ssl.truststore.password=confluent \
           --property basic.auth.credentials.source=USER_INFO \
           --property schema.registry.basic.auth.user.info=badapp:badapp \
           --group wikipedia.test \
           --topic wikipedia.parsed \
           --max-messages 5

#. View all the role bindings that were configured for RBAC in this cluster.

   .. sourcecode:: bash

          ./scripts/validate/validate_bindings.sh

#. Because |zk| is configured for `SASL/DIGEST-MD5 <https://docs.confluent.io/current/kafka/authentication_sasl_plain.html#zookeeper>`__, any commands that communicate with |zk| need properties set for |zk| authentication. This authentication configuration is provided by the ``KAFKA_OPTS`` setting on the brokers. For example, notice that the `throttle script <scripts/app/throttle_consumer.sh>`__ runs on the Docker container ``kafka1`` which has the appropriate `KAFKA_OPTS` setting. The command would otherwise fail if run on any other container aside from ``kafka1`` or ``kafka2``.

#. Next step: Learn more about security with the :ref:`Security Tutorial <security_tutorial>`.


Data Governance with |sr|
-------------------------

All the applications and connectors used in this demo are configured to automatically read and write Avro-formatted data, leveraging the `Confluent Schema Registry <https://docs.confluent.io/current/schema-registry/docs/index.html>`__ .

The security in place between |sr| and the end clients, e.g. ``appSA``, is as follows:

- Encryption: TLS, e.g. client has ``schema.registry.ssl.truststore.*`` configurations
- Authentication: bearer token authentication from HTTP basic auth headers, e.g. client has ``schema.registry.basic.auth.user.info`` and ``basic.auth.credentials.source`` configurations
- Authorization: |sr| uses the bearer token with RBAC to authorize the client


#. View the |sr| subjects for topics that have registered schemas for their keys and/or values. Notice the ``curl`` arguments include (a) TLS information required to interact with |sr| which is listening for HTTPS on port 8085, and (b) authentication credentials required for RBAC (using `superUser:superUser` to see all of them).

   .. sourcecode:: bash

       docker-compose exec schemaregistry curl -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u superUser:superUser https://schemaregistry:8085/subjects | jq .

   Your output should resemble:

   .. sourcecode:: bash

       [
         "wikipedia.parsed.replica-value",
         "EN_WIKIPEDIA_GT_1_COUNTS-value",
         "WIKIPEDIABOT-value",
         "_confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4-Aggregate-aggregate-changelog-value",
         "EN_WIKIPEDIA_GT_1-value",
         "wikipedia.parsed.count-by-channel-value",
         "_confluent-ksql-ksql-clusterquery_CTAS_EN_WIKIPEDIA_GT_1_4-Aggregate-groupby-repartition-value",
         "WIKIPEDIANOBOT-value",
         "wikipedia.parsed-value"
      ]

#. Instead of using the superUser credentials, now use client credentials `noexist:noexist` (user does not exist in LDAP) to try to register a new Avro schema (a record with two fields ``username`` and ``userid``) into |sr| for the value of a new topic ``users``. It should fail due to an authorization error.

   .. sourcecode:: bash

       docker-compose exec schemaregistry curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{ "schema": "[ { \"type\":\"record\", \"name\":\"user\", \"fields\": [ {\"name\":\"userid\",\"type\":\"long\"}, {\"name\":\"username\",\"type\":\"string\"} ]} ]" }' -u noexist:noexist https://schemaregistry:8085/subjects/users-value/versions

   Your output should resemble:

   .. sourcecode:: bash

        {"error_code":401,"message":"Unauthorized"}

#. Instead of using credentials for a user that does not exist, now use the client credentials `appSA:appSA` (the user `appSA` exists in LDAP) to try to register a new Avro schema (a record with two fields ``username`` and ``userid``) into |sr| for the value of a new topic ``users``. It should fail due to an authorization error, with a different message than above.

   .. sourcecode:: bash

       docker-compose exec schemaregistry curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{ "schema": "[ { \"type\":\"record\", \"name\":\"user\", \"fields\": [ {\"name\":\"userid\",\"type\":\"long\"}, {\"name\":\"username\",\"type\":\"string\"} ]} ]" }' -u appSA:appSA https://schemaregistry:8085/subjects/users-value/versions

   Your output should resemble:

   .. sourcecode:: bash

      {"error_code":40403,"message":"User is denied operation Write on Subject: users-value"}

#. Create a role binding for the ``appSA`` client permitting it access to |sr|.

   .. sourcecode:: bash

      # First get the KAFKA_CLUSTER_ID
      KAFKA_CLUSTER_ID=$(docker-compose exec zookeeper zookeeper-shell zookeeper:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)

      # Then create the role binding for the subject ``users-value``, i.e., the topic-value (versus the topic-key)
      docker-compose exec tools bash -c "confluent iam rolebinding create \
          --principal User:appSA \
          --role ResourceOwner \
          --resource Subject:users-value \
          --kafka-cluster-id $KAFKA_CLUSTER_ID \
          --schema-registry-cluster-id schema-registry"

#. Again try to register the schema. It should pass this time.  Note the schema id that it returns, e.g. below schema id is ``7``.

   .. sourcecode:: bash

       docker-compose exec schemaregistry curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{ "schema": "[ { \"type\":\"record\", \"name\":\"user\", \"fields\": [ {\"name\":\"userid\",\"type\":\"long\"}, {\"name\":\"username\",\"type\":\"string\"} ]} ]" }' -u appSA:appSA https://schemaregistry:8085/subjects/users-value/versions

   Your output should resemble:

   .. sourcecode:: bash

     {"id":7}

#. View the new schema for the subject ``users-value``. From |c3|, click **Topics**. Scroll down to and click on the topic `users` and select "SCHEMA".

   .. figure:: images/schema1.png
    :alt: image
   
   You may alternatively request the schema via the command line:

   .. sourcecode:: bash

       docker-compose exec schemaregistry curl -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u appSA:appSA https://schemaregistry:8085/subjects/users-value/versions/1 | jq .

   Your output should resemble:

   .. sourcecode:: bash

     {
       "subject": "users-value",
       "version": 1,
       "id": 7,
       "schema": "{\"type\":\"record\",\"name\":\"user\",\"fields\":[{\"name\":\"username\",\"type\":\"string\"},{\"name\":\"userid\",\"type\":\"long\"}]}"
     }

#. Next step: Learn more about |sr| with the :ref:`Schema Registry Tutorial <schema_registry_tutorial>`.


Confluent REST Proxy
--------------------

The `Confluent REST Proxy <https://docs.confluent.io/current/kafka-rest/docs/index.html>`__  is running for optional client access.

#. Use the |crest|, which is listening for HTTPS on port 8086, to try to produce a message to the topic ``users``, referencing schema id ``7``. This schema was registered in |sr| in the previous section. It should fail due to an authorization error.

   .. sourcecode:: bash

     docker-compose exec restproxy curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" -H "Accept: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{"value_schema_id": 7, "records": [{"value": {"user":{"userid": 1, "username": "Bunny Smith"}}}]}' -u appSA:appSA https://restproxy:8086/topics/users

   Your output should resemble:

   .. sourcecode:: bash

      {"offsets":[{"partition":null,"offset":null,"error_code":40301,"error":"Not authorized to access topics: [users]"}],"key_schema_id":null,"value_schema_id":7}

#. Create a role binding for the client permitting it produce to the topic ``users``.

   .. sourcecode:: bash

      # First get the KAFKA_CLUSTER_ID
      KAFKA_CLUSTER_ID=$(docker-compose exec zookeeper zookeeper-shell zookeeper:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)

      # Then create the role binding for the topic ``users``
      docker-compose exec tools bash -c "confluent iam rolebinding create \
          --principal User:appSA \
          --role DeveloperWrite \
          --resource Topic:users \
          --kafka-cluster-id $KAFKA_CLUSTER_ID" 

#. Again try to produce a message to the topic ``users``. It should pass this time.

   .. sourcecode:: bash

     docker-compose exec restproxy curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" -H "Accept: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{"value_schema_id": 7, "records": [{"value": {"user":{"userid": 1, "username": "Bunny Smith"}}}]}' -u appSA:appSA https://restproxy:8086/topics/users

   Your output should resemble:

   .. sourcecode:: bash

     {"offsets":[{"partition":1,"offset":0,"error_code":null,"error":null}],"key_schema_id":null,"value_schema_id":7}

#. Create consumer instance ``my_avro_consumer``.

   .. sourcecode:: bash

       docker-compose exec restproxy curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{"name": "my_consumer_instance", "format": "avro", "auto.offset.reset": "earliest"}' -u appSA:appSA https://restproxy:8086/consumers/my_avro_consumer

   Your output should resemble:

   .. sourcecode:: bash

      {"instance_id":"my_consumer_instance","base_uri":"https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance"}

#. Subscribe ``my_avro_consumer`` to the ``users`` topic.

   .. sourcecode:: bash

       docker-compose exec restproxy curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{"topics":["users"]}' -u appSA:appSA https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance/subscription

#. Try to consume messages for ``my_avro_consumer`` subscriptions. It should fail due to an authorization error.

   .. sourcecode:: bash

       docker-compose exec restproxy curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u appSA:appSA https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance/records
  
   Your output should resemble:

   .. sourcecode:: bash

        {"error_code":40301,"message":"Not authorized to access group: my_avro_consumer"} 

#. Create a role binding for the client permitting it access to the consumer group ``my_avro_consumer``.

   .. sourcecode:: bash

      # First get the KAFKA_CLUSTER_ID
      KAFKA_CLUSTER_ID=$(docker-compose exec zookeeper zookeeper-shell zookeeper:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)

      # Then create the role binding for the group ``my_avro_consumer``
      docker-compose exec tools bash -c "confluent iam rolebinding create \
          --principal User:appSA \
          --role ResourceOwner \
          --resource Group:my_avro_consumer \
          --kafka-cluster-id $KAFKA_CLUSTER_ID"

#. Again try to consume messages for ``my_avro_consumer`` subscriptions. It should fail due to a different authorization error.

   .. sourcecode:: bash

       # Note: Issue this command twice due to https://github.com/confluentinc/kafka-rest/issues/432
       docker-compose exec restproxy curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u appSA:appSA https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance/records
       docker-compose exec restproxy curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u appSA:appSA https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance/records

   Your output should resemble:

   .. sourcecode:: bash

      {"error_code":40301,"message":"Not authorized to access topics: [users]"}

#. Create a role binding for the client permitting it access to the topic ``users``.

   .. sourcecode:: bash

      # First get the KAFKA_CLUSTER_ID
      KAFKA_CLUSTER_ID=$(docker-compose exec zookeeper zookeeper-shell zookeeper:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)

      # Then create the role binding for the group my_avro_consumer
      docker-compose exec tools bash -c "confluent iam rolebinding create \
          --principal User:appSA \
          --role DeveloperRead \
          --resource Topic:users \
          --kafka-cluster-id $KAFKA_CLUSTER_ID"

#. Again try to consume messages for ``my_avro_consumer`` subscriptions. It should pass this time.

   .. sourcecode:: bash

       # Note: Issue this command twice due to https://github.com/confluentinc/kafka-rest/issues/432
       docker-compose exec restproxy curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u appSA:appSA https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance/records
       docker-compose exec restproxy curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u appSA:appSA https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance/records

    Your output should resemble:

   .. sourcecode:: bash

      [{"topic":"users","key":null,"value":{"userid":1,"username":"Bunny Smith"},"partition":1,"offset":0}]

#. Delete the consumer instance ``my_avro_consumer``.

   .. sourcecode:: bash

       docker-compose exec restproxy curl -X DELETE -H "Content-Type: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt -u appSA:appSA https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance


Failed Broker
-------------

To simulate a failed broker, stop the Docker container running one of
the two Kafka brokers.

#. Stop the Docker container running Kafka broker 2.

   .. sourcecode:: bash

          docker-compose stop kafka2

#. After a few minutes, observe the Broker summary show that the number of brokers 
   has decreased from 2 to 1, and there are many under replicated
   partitions.

   .. figure:: images/broker_down_failed.png
      :alt: image

#. View Topic information details to see that there are out of sync replicas on broker 2.

   .. figure:: images/broker_down_replicas.png
      :alt: image

#. Look at the production and consumption metrics and notice that the clients are all still working.

   .. figure:: images/broker_down_apps_working.png
      :alt: image

#. Restart the Docker container running Kafka broker 2.

   .. sourcecode:: bash

          docker-compose start kafka2

#. After about a minute, observe the Broker summary in Confluent
   Control Center. The broker count has recovered to 2, and the topic
   partitions are back to reporting no under replicated partitions.

   .. figure:: images/broker_down_steady.png
      :alt: image

#. Click on the broker count ``2`` inside the "Broker uptime" box to view when
   broker counts changed.

   .. figure:: images/broker_down_times.png
      :alt: image


Alerting
--------

There are many types of Control Center
`alerts <https://docs.confluent.io/current/control-center/docs/alerts.html>`__
and many ways to configure them. Use the Alerts management page to
define triggers and actions, or click on individual resources
to setup alerts from there.

.. figure:: images/c3-alerts-bell-icon-initial.png
   :alt: image


#. This demo already has pre-configured triggers and actions. View the
   Alerts ``Triggers`` screen, and click ``Edit`` against each trigger
   to see configuration details.

   -  The trigger ``Under Replicated Partitions`` happens when a broker
      reports non-zero under replicated partitions, and it causes an
      action ``Email Administrator``.
   -  The trigger ``Consumption Difference`` happens when consumption
      difference for the Elasticsearch connector consumer group is
      greater than ``0``, and it causes an action
      ``Email Administrator``.

   .. figure:: images/alerts_triggers.png
      :alt: image

#. If you followed the steps in the `failed broker <#failed-broker>`__
   section, view the Alert history to see that the trigger
   ``Under Replicated Partitions`` happened and caused an alert when you
   stopped broker 2.


   .. figure:: images/alerts_triggers_under_replication_partitions.png
      :alt: image


#. You can also trigger the ``Consumption Difference`` trigger. In the
   Kafka Connect -> Sinks screen, edit the running Elasticsearch sink
   connector.

#. In the Connect view, pause the Elasticsearch sink connector in Settings by
   pressing the pause icon in the top right. This will stop consumption
   for the related consumer group.

   .. figure:: images/pause_connector.png
      :alt: image

#. View the Alert history to see that this trigger happened and caused
   an alert.

   .. figure:: images/trigger_history.png
      :alt: image


===============
Troubleshooting
===============

Here are some suggestions on how to troubleshoot the demo.

#. Verify the status of the Docker containers show ``Up`` state, except for the ``kafka-client`` container which is expected to have ``Exit 0`` state. If any containers are not up, verify in the advanced Docker preferences settings that the memory available to Docker is at least 8 GB (default is 2 GB).

   .. sourcecode:: bash

        docker-compose ps

   Your output should resemble:

   .. sourcecode:: bash

                 Name                          Command                  State                                           Ports                                     
      ------------------------------------------------------------------------------------------------------------------------------------------------------------
      connect                       bash -c sleep 10 && cp /us ...   Up             0.0.0.0:8083->8083/tcp, 9092/tcp
      control-center                /etc/confluent/docker/run        Up (healthy)   0.0.0.0:9021->9021/tcp, 0.0.0.0:9022->9022/tcp
      elasticsearch                 /bin/bash bin/es-docker          Up             0.0.0.0:9200->9200/tcp, 0.0.0.0:9300->9300/tcp
      kafka-client                  bash -c -a echo Waiting fo ...   Exit 0
      kafka1                        bash -c if [ ! -f /etc/kaf ...   Up (healthy)   0.0.0.0:10091->10091/tcp, 0.0.0.0:11091->11091/tcp, 0.0.0.0:12091->12091/tcp,
                                                                                    0.0.0.0:8091->8091/tcp, 0.0.0.0:9091->9091/tcp, 9092/tcp
      kafka2                        bash -c if [ ! -f /etc/kaf ...   Up (healthy)   0.0.0.0:10092->10092/tcp, 0.0.0.0:11092->11092/tcp, 0.0.0.0:12092->12092/tcp,
                                                                                    0.0.0.0:8092->8092/tcp, 0.0.0.0:9092->9092/tcp
      kibana                        /bin/sh -c /usr/local/bin/ ...   Up             0.0.0.0:5601->5601/tcp
      ksql-cli                      /bin/sh                          Up
      ksql-server                   /etc/confluent/docker/run        Up (healthy)   0.0.0.0:8088->8088/tcp
      openldap                      /container/tool/run --copy ...   Up             0.0.0.0:389->389/tcp, 636/tcp
      replicator-for-jar-transfer   sleep infinity                   Up             8083/tcp, 9092/tcp
      restproxy                     /etc/confluent/docker/run        Up             8082/tcp, 0.0.0.0:8086->8086/tcp
      schemaregistry                /etc/confluent/docker/run        Up             8081/tcp, 0.0.0.0:8085->8085/tcp
      streams-demo                  /app/start.sh                    Up             9092/tcp
      tools                         /bin/bash                        Up
      zookeeper                     /etc/confluent/docker/run        Up (healthy)   0.0.0.0:2181->2181/tcp, 2888/tcp, 3888/tcp


#. To view sample messages for each topic, including
   ``wikipedia.parsed``:

   .. sourcecode:: bash

          ./scripts/consumers/listen.sh

#. If a command that communicates with |zk| appears to be failing with the error ``org.apache.zookeeper.KeeperException$NoAuthException``,
   change the container you are running the command from to be either ``kafka1`` or ``kafka2``.  This is because |zk| is configured for
   `SASL/DIGEST-MD5 <https://docs.confluent.io/current/kafka/authentication_sasl_plain.html#zookeeper>`__, and
   any commands that communicate with |zk| need properties set for |zk| authentication.

#. Run any of the :devx-cp-demo:`validation scripts|scripts/validate/` to check that things are working.

   .. sourcecode:: bash

          cd scripts/validate/


      
========
Teardown
========

#. Stop the consumer group ``app`` to stop consuming from topic
   ``wikipedia.parsed``. Note that the command below stops the consumers
   gracefully with ``kill -15``, so the consumers follow the shutdown
   sequence.

   .. code:: bash

         ./scripts/app/stop_consumer_app_group_graceful.sh

#. Stop the Docker demo, destroy all components and clear all Docker
   volumes.

   .. sourcecode:: bash

          ./scripts/stop.sh

