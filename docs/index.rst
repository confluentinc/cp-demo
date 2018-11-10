.. _cp-demo:

Monitoring Kafka streaming ETL deployments
==========================================

This demo shows users how to deploy a Kafka streaming ETL using `KSQL <https://www.confluent.io/product/ksql/>`__ for stream processing and `Confluent Control Center <https://www.confluent.io/product/control-center/>`__ for monitoring. All the components in the Confluent platform have security enabled end-to-end.

========
Overview
========

The use case is a streaming ETL deployment for real-time edits to real Wikipedia
pages. Wikimedia Foundation has IRC channels that publish edits
happening to real wiki pages (e.g. ``#en.wikipedia``, ``#en.wiktionary``) in
real time. Using `Kafka
Connect <http://docs.confluent.io/current/connect/index.html>`__, a
Kafka source connector
`kafka-connect-irc <https://github.com/cjmatta/kafka-connect-irc>`__
streams raw messages from these IRC channels, and a custom Kafka Connect
transform
`kafka-connect-transform-wikiedit <https://github.com/cjmatta/kafka-connect-transform-wikiedit>`__
transforms these messages and then the messages are written to a Kafka
cluster. This demo uses `KSQL <https://www.confluent.io/product/ksql/>`__
for data enrichment, or you can optionally develop and run your own
`Kafka Streams <http://docs.confluent.io/current/streams/index.html>`__
application. Then a Kafka sink connector
`kafka-connect-elasticsearch <http://docs.confluent.io/current/connect/connect-elasticsearch/docs/elasticsearch_connector.html>`__
streams the data out of Kafka, applying another custom Kafka Connect
transform called NullFilter. The data is materialized into
`Elasticsearch <https://www.elastic.co/products/elasticsearch>`__ for
analysis by `Kibana <https://www.elastic.co/products/kibana>`__.

.. figure:: images/drawing.png
    :alt: image


.. note:: This is a Docker environment and has all services running on one host. Do not use this demo in production. It is meant exclusively to easily demo the |CP|. In production, |c3| should be deployed with a valid license and with its own dedicated metrics cluster, separate from the cluster with production traffic. Using a dedicated metrics cluster is more resilient because it continues to provide system health monitoring even if the production traffic cluster experiences issues.

If you are completely new to |c3|, watch a brief video overview `Monitoring Kafka Like a Pro <https://youtu.be/O9LqDGSoWaU>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/O9LqDGSoWaU" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>


========
Run demo
========

**Demo validated with:**

-  Docker version 17.06.1-ce
-  Docker Compose version 1.14.0 with Docker Compose file format 2.1
-  Java version 1.8.0_92
-  MacOS 10.12
-  git
-  jq

.. note:: If you prefer a non-Docker version and have Elasticsearch and Kibana running on your local machine, please follow `these instructions <https://github.com/confluentinc/quickstart-demos/tree/master/wikipedia>`__.


1. Clone the `cp-demo GitHub repository <https://github.com/confluentinc/cp-demo>`__:

   .. sourcecode:: bash

       git clone https://github.com/confluentinc/cp-demo

2. In Docker's advanced `settings <https://docs.docker.com/docker-for-mac/#advanced>`__, increase the memory dedicated to Docker to at least 8GB (default is 2GB).

3. From the ``cp-demo`` directory, start the entire demo by running a single command that generates the keys and certificates, brings up the Docker containers, and configures and validates the environment. This will take less than 5 minutes to complete.

   .. sourcecode:: bash

        ./scripts/start.sh

4. Use Google Chrome to view the |c3| GUI at http://localhost:9021. Click on the top right button that shows the current date, and change ``Last 4 hours`` to ``Last 30 minutes``.

5. View the data in the Kibana dashboard at http://localhost:5601/app/kibana#/dashboard/Wikipedia


========
Playbook
========

|c3| Tour
--------------------------------

Follow along with the `Demo 2: Tour <https://youtu.be/D9nzAxxIv7A>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/D9nzAxxIv7A" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>

1. **MONITORING –> System Health**: |c3| landing
   page shows the overall `system
   health <https://docs.confluent.io/current/control-center/docs/systemhealth.html>`__
   of a given Kafka cluster. For capacity planning activities, view
   cluster utilization:

   -  CPU: look at network and thread pool usage, produce and fetch
      request latencies
   -  Network utilization: look at throughput per broker or per cluster
   -  Disk utilization: look at disk space used by all log segments, per
      broker

   .. figure:: images/landing_page.png




2. **MANAGEMENT –> Kafka Connect**: |c3| uses
   the Kafka Connect API to manage `Kafka
   connectors <https://docs.confluent.io/current/control-center/docs/connect.html>`__.

   -  Kafka Connect **Sources** tab shows the connectors
      ``wikipedia-irc`` and ``replicate-topic``. Click ``Edit`` to see
      the details of the connector configuration and custom transforms.

      .. figure:: images/connect_source.png
         :alt: image
   



   -  Kafka Connect **Sinks** tab shows the connector
      ``elasticsearch-ksql``. Click ``Edit`` to see the details of the
      connector configuration and custom transforms.

      .. figure:: images/connect_sink.png
         :alt: image



3. **MONITORING –> Data Streams –> Message Delivery**: hover over
   any chart to see number of messages and average latency within a
   minute time interval.

   .. figure:: images/message_delivery.png
      :alt: image



   The Kafka Connect sink connectors have corresponding consumer groups
   ``connect-elasticsearch-ksql`` and ``connect-replicator``. These
   consumer groups will be in the consumer group statistics in the
   `stream
   monitoring <https://docs.confluent.io/current/control-center/docs/monitoring.html>`__
   charts.

   .. figure:: images/connect_consumer_group.png
      :alt: image


4. **MONITORING –> System Health**: to identify bottlenecks, you can
   see a breakdown of produce and fetch latencies through the entire
   `request
   lifecycle <https://docs.confluent.io/current/control-center/docs/systemhealth.html>`__.
   Click on the line graph in the ``Request latency`` chart. The request
   latency values can be shown at the median, 95th, 99th, or 99.9th
   percentile. Depending on where the bottlenecks are, you can tune your
   brokers and clients appropriately.

   .. figure:: images/request_latencies.png
      :alt: image


Topic Management
--------------------------------

|c3| has a useful interface to manage topics in a Kafka cluster.

1. **MANAGEMENT –> Topics**: Scroll down to and click on the topic `wikipedia.parsed`.

      .. figure:: images/topic_actions.png
         :alt: image

2. **MANAGEMENT –> Topics -> Status**: View which brokers are leaders for which partitions and where all partitions reside.

   .. figure:: images/topic_info.png
      :alt: image

3. **MANAGEMENT –> Topics -> Schema**: View the schema for this topic. For `wikipedia.parsed`, the topic value is using a Schema registered with |sr| (the topic key is just a string).

   .. figure:: images/topic_schema.png
      :alt: image

4. **MANAGEMENT –> Topics -> Inspect**: View messages for this topic, in real-time.

   .. figure:: images/topic_inspect.png
      :alt: image

5. **MANAGEMENT –> Topics -> Settings**: View configuration settings for this topic.

   .. figure:: images/topic_settings.png
      :alt: image

6. **MANAGEMENT -> Topics**: click the ``+ Create`` button on the top right to create a new topic in your Kafka cluster. You can also view and edit settings of Kafka topics in the cluster. Read more on |c3| `topic management <https://docs.confluent.io/current/control-center/docs/topics.html>`__.

      .. figure:: images/create_topic.png
         :alt: image

.. _ksql-demo-3:

KSQL
----

Follow along with the `Demo 3: KSQL <https://youtu.be/3o7MzCri4e4>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/3o7MzCri4e4" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>

In this demo, KSQL is authenticated and authorized to connect to the secured Kafka cluster, and it is already running queries as defined in the `KSQL command file <https://github.com/confluentinc/cp-demo/blob/master/scripts/ksql/ksqlcommands>`__.

1. The KSQL server is listening on port 8088. You have two options for interfacing with KSQL:

   (a) Use Control Center's integrated `KSQL UI <http://localhost:9021/management/ksql/ksql-server%3A8088/streams>`__. From the |c3| UI, click **DEVELOPMENT –> KSQL**:

       .. figure:: images/development_ksql.png
          :alt: image

   (b) Run KSQL CLI to get to the KSQL CLI prompt.

       .. sourcecode:: bash

            docker-compose exec ksql-cli ksql http://ksql-server:8088

2. **DEVELOPMENT -> KSQL -> STREAMS**: View the existing KSQL streams. (If you are using the KSQL CLI, at the ``ksql>`` prompt type ``SHOW STREAMS;``).

     .. figure:: images/ksql_streams_list.png
        :alt: image

3. **DEVELOPMENT -> KSQL -> STREAMS**: Describe the schema (fields or columns) and source and sink of an existing KSQL stream. Click on ``WIKIPEDIA``.

     .. figure:: images/wikipedia_describe.png
        :alt: image

4. **DEVELOPMENT -> KSQL -> TABLES**: View the existing KSQL tables. (If you are using the KSQL CLI, at the ``ksql>`` prompt type ``SHOW TABLES;``).

     .. figure:: images/ksql_tables_list.png
        :alt: image

5. **DEVELOPMENT -> KSQL -> PERSISTENT QUERIES**: View the existing KSQL queries, which are continuously running. (If you are using the KSQL CLI, at the ``ksql>`` prompt type ``SHOW QUERIES;``).

     .. figure:: images/ksql_queries_list.png
        :alt: image

6. **DEVELOPMENT -> KSQL -> STREAMS**: View messages from different KSQL streams and tables. Right click on your stream of choice, select ``Query`` which takes you to the Query Editor with a pre-populated query such as ``select * from WIKIPEDIA limit 5;``.  Click on the ``Run query`` button to run.

     .. figure:: images/ksql_query_topic.png
        :alt: image

7. **DEVELOPMENT -> KSQL -> STREAMS**: Create a new stream from an existing topic. Click on the button ``Create Stream`` and follow the prompts.

8. **DEVELOPMENT -> KSQL -> QUERY EDITOR**: View the configured KSQL server properties set in the docker-compose.yml file. In the query editor, type ``SHOW PROPERTIES;`` and then click on the ``Run query`` button.

     .. figure:: images/ksql_properties.png
        :alt: image

9. In this demo, KSQL is run with Confluent Monitoring Interceptors configured which enables |c3| Data Streams to monitor KSQL queries. The consumer group names ``ksql_query_`` correlate to the KSQL query names above, and |c3| is showing the records that are incoming to each query.

* View throughput and latency of the incoming records for the persistent KSQL "Create Stream As Select" query ``CSAS_WIKIPEDIABOT``, which is displayed as ``ksql_query_CSAS_WIKIPEDIABOT`` in |c3|.

   .. figure:: images/ksql_query_CSAS_WIKIPEDIABOT.png
      :alt: image

* View throughput and latency of the incoming records for the persistent KSQL "Create Table As Select" query ``CTAS_EN_WIKIPEDIA_GT_1``, which is displayed as ``ksql_query_CTAS_EN_WIKIPEDIA_GT_1`` in |c3|.

   .. figure:: images/ksql_query_CTAS_EN_WIKIPEDIA_GT_1.png
      :alt: image

* View throughput and latency of the incoming records for the persistent KSQL "Create Stream As Select" query ``CTAS_EN_WIKIPEDIA_GT_1_COUNTS``, which is displayed as ``ksql_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS`` in |c3|.

   .. figure:: images/tumbling_window.png
      :alt: image

   .. note:: In |c3| the stream monitoring graphs for consumer groups ``ksql_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS`` and ``EN_WIKIPEDIA_GT_1_COUNTS-consumer`` are displaying data at 5-minute intervals instead of smoothly like the other consumer groups. This is because |c3| displays data based on message timestamps, and the incoming stream for these consumer groups is a tumbling window with a window size of 5 minutes. Thus all its messages are timestamped to the beginning of each 5-minute window. This is also why the latency for these streams appears to be high. Kafka streaming tumbling windows are working as designed, and |c3| is reporting them accurately.

10. This demo creates two streams ``EN_WIKIPEDIA_GT_1`` and ``EN_WIKIPEDIA_GT_1_COUNTS``, and the reason is to demonstrate how KSQL windows work. ``EN_WIKIPEDIA_GT_1`` counts occurences with a tumbling window, and for a given key it writes a `null` into the table on the first seen message.  The underlying Kafka topic for ``EN_WIKIPEDIA_GT_1`` does not filter out those nulls, but since we want to send downstream just the counts greater than one, there is a separate Kafka topic for ````EN_WIKIPEDIA_GT_1_COUNTS`` which does filter out those nulls (e.g., the query has a clause ``where ROWTIME is not null``).  From the bash prompt, view those underlying Kafka topics.

   .. sourcecode:: bash

        docker exec connect kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic EN_WIKIPEDIA_GT_1 \
        --property schema.registry.url=https://schemaregistry:8085 \
        --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 10
      null
      {"USERNAME":"Atsme","WIKIPAGE":"Wikipedia:Articles for deletion/Metallurg Bratsk","COUNT":2}
      null
      null
      null
      {"USERNAME":"7.61.29.178","WIKIPAGE":"Tandem language learning","COUNT":2}
      {"USERNAME":"Attar-Aram syria","WIKIPAGE":"Antiochus X Eusebes","COUNT":2}
      ...

        docker exec connect kafka-avro-console-consumer --bootstrap-server kafka1:9091 --topic EN_WIKIPEDIA_GT_1_COUNTS \
        --property schema.registry.url=https://schemaregistry:8085 \
        --consumer.config /etc/kafka/secrets/client_without_interceptors.config --max-messages 10
      {"USERNAME":"Atsme","COUNT":2,"WIKIPAGE":"Wikipedia:Articles for deletion/Metallurg Bratsk"}
      {"USERNAME":"7.61.29.178","COUNT":2,"WIKIPAGE":"Tandem language learning"}
      {"USERNAME":"Attar-Aram syria","COUNT":2,"WIKIPAGE":"Antiochus X Eusebes"}
      {"USERNAME":"RonaldB","COUNT":2,"WIKIPAGE":"Wikipedia:Open proxy detection"}
      {"USERNAME":"Dormskirk","COUNT":2,"WIKIPAGE":"Swindon Designer Outlet"}
      {"USERNAME":"B.Bhargava Teja","COUNT":3,"WIKIPAGE":"Niluvu Dopidi"}
      ...


Consumer rebalances
-------------------

Follow along with the `Demo 4: Consumer Rebalances <https://youtu.be/2Egh3I0q4dE>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/2Egh3I0q4dE" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>

Control Center shows which consumers in a consumer group are consuming
from which partitions and on which brokers those partitions reside.
Control Center updates as consumer rebalances occur in a consumer group.

1. Start consuming from topic ``wikipedia.parsed`` with a new consumer
   group ``app`` with one consumer ``consumer_app_1``. It will run in
   the background.

   .. sourcecode:: bash

          ./scripts/app/start_consumer_app.sh 1

2. Let this consumer group run for 2 minutes until Control Center stream
   monitoring shows the consumer group ``app`` with steady consumption.
   Click on the box ``View Details`` above the bar graph to drill down
   into consumer group details. This consumer group ``app`` has a single
   consumer ``consumer_app_1`` consuming all of the partitions in the
   topic ``wikipedia.parsed``. The first bar may be red because the
   consumer started in the middle of a time window and did not receive
   all messages produced during that window. This does not mean messages
   were lost.

   .. figure:: images/consumer_start_one.png
      :alt: image



3. Add a second consumer ``consumer_app_2`` to the existing consumer
   group ``app``.

   .. sourcecode:: bash

          ./scripts/app/start_consumer_app.sh 2

4. Let this consumer group run for 2 minutes until Control Center stream
   monitoring shows the consumer group ``app`` with steady consumption.
   Notice that the consumers ``consumer_app_1`` and ``consumer_app_2``
   now share consumption of the partitions in the topic
   ``wikipedia.parsed``. When the second consumer was added, that bar
   may be red for both consumers because a consumer rebalance occurred
   during that time window. This does not mean messages were lost, as
   you can confirm at the consumer group level.

   .. figure:: images/consumer_start_two.png
      :alt: image



Slow consumers
--------------

Follow along with the `Demo 5: Slow Consumers <https://youtu.be/XOtY1uUaf_Y>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/XOtY1uUaf_Y" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>

Streams monitoring in Control Center can highlight consumers that are
slow to keep up with the producers. This is critial to monitor for
real-time applications where consumers should consume produced messages
with as low latency as possible. To simulate a slow consumer, we will
use Kafka’s `quota
feature <https://docs.confluent.io/current/kafka/post-deployment.html#enforcing-client-quotas>`__
to rate-limit consumption from the broker side, for just one of two
consumers in a consumer group.

1. Click on ``Data streams``, and ``View Details`` for the consumer
   group ``app``. Click on the left-hand blue circle on the consumption
   line to verify there are two consumers ``consumer_app_1`` and
   ``consumer_app_2``, that were created in an earlier section. If these
   two consumers are not running, start them as described in the section
   `consumer rebalances <#consumer-rebalances>`__.

2. Let this consumer group run for 2 minutes until Control Center stream
   monitoring shows the consumer group ``app`` with steady consumption.

3. Add a consumption quota for one of the consumers in the consumer
   group ``app``.

   .. sourcecode:: bash

          ./scripts/app/throttle_consumer.sh 1 add

   .. note:: You are running a Docker demo environment with all services running on one host, which you would never do in production.  Depending on your system resource availability, sometimes applying the quota may stall the consumer (`KAFKA-5871 <https://issues.apache.org/jira/browse/KAFKA-5871>`__), thus you may need to adjust the quota rate. See the ``./scripts/app/throttle_consumer.sh`` script for syntax on modifying the quota rate.

      -  If consumer group ``app`` does not increase latency, decrease the quota rate
      -  If consumer group ``app`` seems to stall, increase the quota rate


4. View the details of the consumer group ``app`` again,
   ``consumer_app_1`` now shows high latency, and ``consumer_app_2``
   shows normal latency.

   .. figure:: images/slow_consumer.png
      :alt: image

5. In the System Health dashboard, you see that the fetch request
   latency has likewise increased. This is the because the broker that
   has the partition that ``consumer_app_1`` is consuming from is taking
   longer to service requests.

   .. figure:: images/slow_consumer_fetch_latency.png
      :alt: image

6. Click on the fetch request latency line graph to see a breakdown of
   produce and fetch latencies through the entire `request
   lifecycle <https://docs.confluent.io/current/control-center/docs/systemhealth.html>`__.
   The middle number does not necessarily equal the sum of the
   percentiles of individual segments because it is the total percentile
   latency.

   .. figure:: images/slow_consumer_fetch_latency_breakdown.png
      :alt: image

7. **MONITORING -> Consumer lag**: consumer lag is the topic's high water mark (latest offset for the topic that has been written) minus the current consumer offset (latest offset read for that topic by that consumer group). Keep in mind topic write rate and consumer group read rate when considering what the significance of how big is the consumer lag. In the demo, view the consumer lag for the ``app`` consumer group: expect consumer 1 to be have much more lag than consumer 2 because of the throttle you added in an earlier step. 

   .. figure:: images/consumer_lag_app.png
      :alt: image

8. Remove the consumption quota for the consumer. Latency for
   ``consumer_app_1`` recovers to steady state values.

   .. sourcecode:: bash

          ./scripts/app/throttle_consumer.sh 1 delete


Over consumption
----------------

Follow along with the `Demo 6: Over Consumption <https://youtu.be/ZYnoG59xNCI>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/ZYnoG59xNCI" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>


Streams monitoring in Control Center can highlight consumers that are
over consuming some messages, which is an indication that consumers are
processing a set of messages more than once. This may happen
intentionally, for example an application with a software bug consumed
and processed Kafka messages incorrectly, got a fix, and then
reprocesses previous messages correctly. This may also happen
unintentionally if an application crashes before committing processed
messages. To simulate over consumption, we will use Kafka’s consumer
offset reset tool to set the offset of the consumer group ``app`` to an
earlier offset, thereby forcing the consumer group to reconsume messages
it has previously read.

1. Click on ``Data streams``, and ``View Details`` for the consumer
   group ``app``. Click on the blue circle on the consumption line on
   the left to verify there are two consumers ``consumer_app_1`` and
   ``consumer_app_2``, that were created in an earlier section. If these
   two consumers are not running and were never started, start them as
   described in the section `consumer
   rebalances <#consumer-rebalances>`__.

   .. figure:: images/verify_two_consumers.png
      :alt: image

2. Let this consumer group run for 2 minutes until Control Center stream
   monitoring shows the consumer group ``app`` with steady consumption.

3. Stop the consumer group ``app`` to stop consuming from topic
   ``wikipedia.parsed``. Note that the command below stops the consumers
   gracefully with ``kill -15``, so the consumers follow the shutdown
   sequence.

   .. sourcecode:: bash

          ./scripts/app/stop_consumer_app_group_graceful.sh

4. Wait for 2 minutes to let messages continue to be written to the
   topics for a while, without being consumed by the consumer group
   ``app``. Notice the red bar which highlights that during the time
   window when the consumer group was stopped, there were some messages
   produced but not consumed. These messages are not missing, they are
   just not consumed because the consumer group stopped.

   .. figure:: images/over_consumption_before_2.png
      :alt: image

5. Reset the offset of the consumer group ``app`` by shifting 200
   offsets backwards. The offset reset tool must be run when the
   consumer is completely stopped. Offset values in output shown below
   will vary.

   .. sourcecode:: bash

         docker-compose exec kafka1 kafka-consumer-groups \
           --reset-offsets --group app --shift-by -200 --bootstrap-server kafka1:10091 \
           --all-topics --execute

   Your output should resemble:

   .. sourcecode:: bash

        TOPIC            PARTITION NEW-OFFSET
        wikipedia.parsed 1         4071
        wikipedia.parsed 0         7944

6. Restart consuming from topic ``wikipedia.parsed`` with the consumer
   group ``app`` with two consumers.

   .. sourcecode:: bash

          ./scripts/app/start_consumer_app.sh 1
          ./scripts/app/start_consumer_app.sh 2

7. Let this consumer group run for 2 minutes until Control Center stream
   monitoring shows the consumer group ``app`` with steady consumption.
   Notice several things:

   -  Even though the consumer group ``app`` was not running for some of
      this time, all messages are shown as delivered. This is because
      all bars are time windows relative to produce timestamp.
   -  For some time intervals, the the bars are red and consumption line
      is above expected consumption because some messages were consumed
      twice due to rewinding offsets.
   -  The latency peaks and then gradually decreases, because this is
      also relative to the produce timestamp.

   .. figure:: images/over_consumption_after_2.png
      :alt: image


Under consumption
-----------------

Follow along with the `Demo 7: Under Consumption <https://youtu.be/d0tZS5FxdM0>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/d0tZS5FxdM0" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>

Streams monitoring in Control Center can highlight consumers that are
under consuming some messages. This may happen intentionally when
consumers stop and restart and operators change the consumer offsets to
the latest offset. This avoids delay processing messages that were
produced while the consumers were stopped, especially when they care
about real-time. This may also happen unintentionally if a consumer is
offline for longer than the log retention period, or if a producer is
configured for ``acks=0`` and a broker suddenly fails before having a
chance to replicate data to other brokers. To simulate under
consumption, we will use Kafka’s consumer offset reset tool to set the
offset of the consumer group ``app`` to the latest offset, thereby
skipping messages that will never be read.

1. Click on Data Streams, and ``View Details`` for the consumer group
   ``app``. Click on the blue circle on the consumption line on the left
   to verify there are two consumers ``consumer_app_1`` and
   ``consumer_app_2``, that were created in an earlier section. If these
   two consumers are not running and were never started, start them as
   described in the section `consumer
   rebalances <#consumer-rebalances>`__.

   .. figure:: images/verify_two_consumers.png
      :alt: image

2. Let this consumer group run for 2 minutes until Control Center stream
   monitoring shows the consumer group ``app`` with steady consumption.

3. Stop the consumer group ``app`` to stop consuming from topic
   ``wikipedia.parsed``. Note that the command below stops the consumers
   ungracefully with ``kill -9``, so the consumers did not follow the
   shutdown sequence.

   .. sourcecode:: bash

          ./scripts/app/stop_consumer_app_group_ungraceful.sh

4. Wait for 2 minutes to let messages continue to be written to the
   topics for a while, without being consumed by the consumer group
   ``app``. Notice the red bar which highlights that during the time
   window when the consumer group was stopped, there were some messages
   produced but not consumed. These messages are not missing, they are
   just not consumed because the consumer group stopped.

   .. figure:: images/under_consumption_before.png
      :alt: image

5. Wait for another few minutes and notice that the bar graph changes
   and there is a
   `herringbone <https://docs.confluent.io/current/control-center/docs/monitoring.html#missing-metrics-data>`__
   pattern to indicate that perhaps the consumer group stopped
   ungracefully.

   .. figure:: images/under_consumption_before_herringbone.png
      :alt: image

6. Reset the offset of the consumer group ``app`` by setting it to
   latest offset. The offset reset tool must be run when the consumer is
   completely stopped. Offset values in output shown below will vary.

   .. sourcecode:: bash

         docker-compose exec kafka1 kafka-consumer-groups \
         --reset-offsets --group app --to-latest --bootstrap-server kafka1:10091 \
         --all-topics --execute

   Your output should resemble:

   .. sourcecode:: bash

       TOPIC            PARTITION NEW-OFFSET
       wikipedia.parsed 1         8601
       wikipedia.parsed 0         15135 

7. Restart consuming from topic ``wikipedia.parsed`` with the consumer
   group ``app`` with two consumers.

   .. sourcecode:: bash

          ./scripts/app/start_consumer_app.sh 1
          ./scripts/app/start_consumer_app.sh 2

8. Let this consumer group run for 2 minutes until Control Center stream
   monitoring shows the consumer group ``app`` with steady consumption.
   Notice that during the time period that the consumer group ``app``
   was not running, no produced messages are shown as delivered.

   .. figure:: images/under_consumption_after.png
      :alt: image


Failed broker
-------------

Follow along with the `Demo 8: Failed Broker <https://youtu.be/oxr1X0t5pLg>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/oxr1X0t5pLg" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>

To simulate a failed broker, stop the Docker container running one of
the two Kafka brokers.

1. Stop the Docker container running Kafka broker 2.

   .. sourcecode:: bash

          docker-compose stop kafka2

2. After a few minutes, observe the System Health shows the broker count
   has gone down from 2 to 1, and there are many under replicated
   partitions.

   .. figure:: images/broker_down_failed.png
      :alt: image

3. View topic details to see that there are out of sync replicas on
   broker 2.

   .. figure:: images/broker_down_replicas.png
      :alt: image

4. Restart the Docker container running Kafka broker 2.

   .. sourcecode:: bash

          docker-compose start kafka2

5. After about a minute, observe the System Health view in Confluent
   Control Center. The broker count has recovered to 2, and the topic
   partitions are back to reporting no under replicated partitions.

   .. figure:: images/broker_down_steady.png
      :alt: image

6. Click on the broker count ``2`` inside the circle to view when the
   broker counts changed.

   .. figure:: images/broker_down_times.png
      :alt: image


Alerting
--------

Follow along with the `Demo 9: Alerting <https://youtu.be/523o_S8OOGo>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/523o_S8OOGo" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>


There are many types of Control Center
`alerts <https://docs.confluent.io/current/control-center/docs/alerts.html>`__
and many ways to configure them. Use the Alerts management page to
define triggers and actions, or click on a streams monitoring graph for
consumer groups or topics to setup alerts from there.

1. This demo already has pre-configured triggers and actions. View the
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

2. If you followed the steps in the `failed broker <#failed-broker>`__
   section, view the Alert history to see that the trigger
   ``Under Replicated Partitions`` happened and caused an alert when you
   stopped broker 2.

3. You can also trigger the ``Consumption Difference`` trigger. In the
   Kafka Connect -> Sinks screen, edit the running Elasticsearch sink
   connector.

4. In the Kafka Connect view, pause the Elasticsearch sink connector by
   pressing the pause icon in the top right. This will stop consumption
   for the related consumer group.

   .. figure:: images/pause_connector.png
      :alt: image

5. View the Alert history to see that this trigger happened and caused
   an alert.

   .. figure:: images/trigger_history.png
      :alt: image


Replicator
----------

Confluent Replicator copies data from a source Kafka cluster to a
destination Kafka cluster. The source and destination clusters are
typically different clusters, but in this demo, Replicator is doing
intra-cluster replication, *i.e.*, the source and destination Kafka
clusters are the same. As with the rest of the components in the
solution, Confluent Replicator is also configured with security.

1. **MONITORING –> Data Streams –> Message Delivery**: monitor
   throughput and latency of Confluent Replicator in the Data streams
   monitoring view. Replicator is a Kafka Connect source connector and
   has a corresponding consumer group ``connect-replicator``.

   .. figure:: images/replicator_consumer_group.png
      :alt: image



2. **MANAGEMENT –> Topics**: scroll down to view the topics called
   ``wikipedia.parsed`` (Replicator is consuming data from this topic)
   and ``wikipedia.parsed.replica`` (Replicator automatically created this topic and is
   copying data to it). Click on ``Consumer Groups`` for the topic
   ``wikipedia.parsed`` and observe that one of the consumer groups is
   called ``connect-replicator``.

   .. figure:: images/replicator_topic_info.png


3. **MANAGEMENT –> Kafka Connect**: pause the Replicator connector
   by pressing the pause icon in the top right. This will stop
   consumption for the related consumer group.

   .. figure:: images/pause_connector.png
      :alt: image

4. Observe that the ``connect-replicator`` consumer group has stopped
   consumption.

   .. figure:: images/replicator_streams_stopped.png




5. Restart the Replicator connector.

6. Observe that the ``connect-replicator`` consumer group has resumed
   consumption. Notice several things:

   * Even though the consumer group `connect-replicator` was not running for some of this time, all messages are shown as delivered. This is because all bars are time windows relative to produce timestamp.
   * The latency peaks and then gradually decreases, because this is also relative to the produce timestamp.

Security
--------

Follow along with the `Security <https://www.youtube.com/watch?v=RwuF7cYcsec>`_ video.

All the components in this demo are enabled with many `security
features <https://docs.confluent.io/current/security.html>`__:

-  `SSL <https://docs.confluent.io/current/kafka/authentication_ssl.html>`__
   for encryption, except for ZooKeeper which does not support SSL
-  `SASL/PLAIN <https://docs.confluent.io/current/kafka/authentication_sasl_plain.html>`__
   for authentication, except for ZooKeeper which is configured for `SASL/DIGEST-MD5 <https://docs.confluent.io/current/kafka/authentication_sasl_plain.html#zookeeper>`__
-  `Authorization <https://docs.confluent.io/current/kafka/authorization.html>`__.
   If a resource has no associated ACLs, then users are not allowed to
   access the resource, except super users
-  `HTTPS for Control Center <https://docs.confluent.io/current/control-center/docs/installation/configuration.html#https-settings>`__
-  `HTTPS for Schema Registry <https://docs.confluent.io/current/schema-registry/docs/security.html>`__
-  `HTTPS for Connect <https://docs.confluent.io/current/connect/security.html#configuring-the-kconnect-rest-api-for-http-or-https>`__

.. note::
    This demo showcases a secure |CP| for educational purposes and is not meant to be complete best practices. There are certain differences between what is shown in the demo and what you should do in production:

    * Each component should have its own username, instead of authenticating all users as ``client``
    * Authorize users only for operations that they need, instead of making all of them super users
    * If the ``PLAINTEXT`` security protocol is used, these ``ANONYMOUS`` usernames should not be configured as super users
    * Consider not even opening the ``PLAINTEXT`` port if ``SSL`` or ``SASL_SSL`` are configured

---------------------------
Encryption & Authentication
---------------------------

Each broker has four listener ports:

-  PLAINTEXT port called ``PLAINTEXT`` for users with no security
   enabled
-  SSL port port called ``SSL`` for users with just SSL without SASL
-  SASL_SSL port called ``SASL_SSL`` for communication between services
   inside Docker containers
-  SASL_SSL port called ``SASL_SSL_HOST`` for communication between any
   potential services outside of Docker that communicate to the Docker
   containers

+---------------+--------+--------+
| port          | kafka1 | kafka2 |
+===============+========+========+
| PLAINTEXT     | 10091  | 10092  |
+---------------+--------+--------+
| SSL           | 11091  | 11092  |
+---------------+--------+--------+
| SASL_SSL      | 9091   | 9092   |
+---------------+--------+--------+
| SASL_SSL_HOST | 29091  | 29092  |
+---------------+--------+--------+

-------------
Authorization
-------------

All the brokers in this demo authenticate as ``broker``, and all other
services authenticate as their respective names. Per the broker configuration
parameter ``super.users``, as it is set in this demo, the only users
that can communicate with the cluster are those that authenticate as
``broker``, ``schemaregistry``, ``client``, ``restproxy``, ``client``, or users
that connect via the ``PLAINTEXT`` port (their username is ``ANONYMOUS``).
All other users are not authorized to communicate with the cluster.

1. Verify the ports on which the Kafka brokers are listening with the
   following command, and they should match the table shown below:

   .. sourcecode:: bash

          docker-compose logs kafka1 | grep "Registered broker 1"
          docker-compose logs kafka2 | grep "Registered broker 2"

2. This demo `automatically
   generates <https://github.com/confluentinc/cp-demo/blob/master/scripts/security/certs-create.sh>`__ simple SSL
   certificates and creates keystores, truststores, and secures them
   with a password. To communicate with the brokers, Kafka clients may
   use any of the ports on which the brokers are listening. To use a
   security-enabled port, they must specify security parameters for
   keystores, truststores, password, or authentication so the Kafka
   command line client tools pass the security configuration file `with
   interceptors <https://github.com/confluentinc/cp-demo/blob/master/scripts/security/client_with_interceptors.config>`__ or
   `without
   interceptors <https://github.com/confluentinc/cp-demo/blob/master/scripts/security/client_without_interceptors.config>`__
   with these security parameters. As an example, to communicate with
   the Kafka cluster to view all the active consumer groups:

   #.  Communicate with brokers via the PLAINTEXT port

       .. sourcecode:: bash

           # PLAINTEXT port
             docker-compose exec kafka1 kafka-consumer-groups --list --bootstrap-server kafka1:10091

   #.  Communicate with brokers via the SASL_SSL port, and SASL_SSL
       parameters configured via the ``--command-config`` argument for
       command line tools or ``--consumer.config`` for
       kafka-console-consumer.

       .. sourcecode:: bash

            # SASL_SSL port with SASL_SSL parameters
              docker-compose exec kafka1 kafka-consumer-groups --list --bootstrap-server kafka1:9091 \
               --command-config /etc/kafka/secrets/client_without_interceptors.config

   #.  If you try to communicate with brokers via the SASL_SSL port but
       don’t specify the SASL_SSL parameters, it will fail

       .. sourcecode:: bash

            # SASL_SSL port without SASL_SSL parameters
              docker-compose exec kafka1 kafka-consumer-groups --list --bootstrap-server kafka1:9091

       Your output should resemble:

       .. sourcecode:: bash

            Error: Executing consumer group command failed due to Request METADATA failed on brokers List(kafka1:9091 (id: -1 rack: null))


3. Verify which authenticated users are configured to be super users.

   .. sourcecode:: bash

         docker-compose logs kafka1 | grep SUPER_USERS

   Your output should resemble the following. Notice this authorizes each service name which authenticates as itself,
   as well as the unauthenticated ``PLAINTEXT`` which authenticates as ``ANONYMOUS`` (for demo purposes only):

   .. sourcecode:: bash

         KAFKA_SUPER_USERS=User:client;User:schemaregistry;User:restproxy;User:broker;User:connect;User:ANONYMOUS

4. Verify that a user ``client`` which authenticates via SASL can
   consume messages from topic ``wikipedia.parsed``:

   .. sourcecode:: bash

          ./scripts/consumers/listen_wikipedia.parsed.sh SASL

5. Verify that a user which authenticates via SSL cannot consume
   messages from topic ``wikipedia.parsed``. It should fail with an exception.

   .. sourcecode:: bash

         ./scripts/consumers/listen_wikipedia.parsed.sh SSL

   Your output should resemble:

   .. sourcecode:: bash

       [2018-01-12 21:13:18,481] ERROR Unknown error when running consumer: (kafka.tools.ConsoleConsumer$)
       org.apache.kafka.common.errors.TopicAuthorizationException: Not authorized to access topics: [wikipedia.parsed]

6. Verify that the broker’s Authorizer logger logs the denial event. As
   shown in the log message, the user which authenticates via SSL has a
   username ``CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US``, not
   just ``client``.

   .. sourcecode:: bash

        # Authorizer logger logs the denied operation
          docker-compose logs kafka1 | grep kafka.authorizer.logger


   Your output should resemble:

   .. sourcecode:: bash

        [2018-01-12 21:13:18,454] INFO Principal = User:CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US is Denied Operation = Describe from host = 172.23.0.7 on resource = Topic:wikipedia.parsed (kafka.authorizer.logger) [2018-01-12
        21:13:18,464] INFO Principal = User:CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US is Denied Operation = Describe from host = 172.23.0.7 on resource = Group:test (kafka.authorizer.logger) 

7. Add an ACL that authorizes user
   ``CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US``, and then
   view the updated ACL configuration.

   .. sourcecode:: bash

      docker-compose exec kafka1 /usr/bin/kafka-acls \
        --authorizer-properties zookeeper.connect=zookeeper:2181 \
        --add --topic wikipedia.parsed \
        --allow-principal User:CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US \
        --operation Read --group test

      docker-compose exec kafka1 /usr/bin/kafka-acls \
        --authorizer-properties zookeeper.connect=zookeeper:2181 \
        --list --topic wikipedia.parsed --group test

   Your output should resemble:

   .. sourcecode:: bash

       Current ACLs for resource ``Topic:wikipedia.parsed``:
       User:CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US has Allow permission for operations: Read from hosts: \*

       Current ACLs for resource ``Group:test``:
       User:CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US has Allow permission for operations: Read from hosts: \* 

8. Verify that the user which authenticates via SSL is now authorized
   and can successfully consume some messages from topic
   ``wikipedia.parsed``.

   .. sourcecode:: bash

          ./scripts/consumers/listen_wikipedia.parsed.sh SSL

9. Because ZooKeeper is configured for `SASL/DIGEST-MD5 <https://docs.confluent.io/current/kafka/authentication_sasl_plain.html#zookeeper>`__, 
   any commands that communicate with ZooKeeper need properties set for ZooKeeper authentication. This authentication configuration is provided
   by the ``KAFKA_OPTS`` setting on the brokers. For example, notice that the `throttle script <scripts/app/throttle_consumer.sh>`__ runs on the
   Docker container ``kafka1`` which has the appropriate `KAFKA_OPTS` setting. The command would otherwise fail if run on any other container aside from ``kafka1`` or ``kafka2``.


|sr| and REST Proxy
-------------------

The connectors used in this demo are configured to automatically read and write Avro-formatted data, leveraging the `Confluent Schema Registry <https://docs.confluent.io/current/schema-registry/docs/index.html>`__ .  The `Confluent REST Proxy <https://docs.confluent.io/current/kafka-rest/docs/index.html>`__  is running for optional client access.

1. View the |sr| subjects for topics that have registered schemas for their keys and/or values. Notice the security arguments passed into the ``curl`` command which are required to interact with |sr|, which is listening for HTTPS on port 8085.

   .. sourcecode:: bash

       docker-compose exec schemaregistry curl -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt https://schemaregistry:8085/subjects | jq .

     [
       "ksql_query_CTAS_EN_WIKIPEDIA_GT_1-KSQL_Agg_Query_1526914100640-changelog-value",
       "ksql_query_CTAS_EN_WIKIPEDIA_GT_1-KSQL_Agg_Query_1526914100640-repartition-value",
       "EN_WIKIPEDIA_GT_1_COUNTS-value",
       "WIKIPEDIABOT-value",
       "EN_WIKIPEDIA_GT_1-value",
       "WIKIPEDIANOBOT-value",
       "wikipedia.parsed-value"
     ]

2. Register a new Avro schema (a record with two fields ``username`` and ``userid``) into |sr| for the value of a new topic ``users``. Note the schema id that it returns, e.g. below schema id is ``6``.

   .. sourcecode:: bash

       docker-compose exec schemaregistry curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{ "schema": "[ { \"type\":\"record\", \"name\":\"user\", \"fields\": [ {\"name\":\"userid\",\"type\":\"long\"}, {\"name\":\"username\",\"type\":\"string\"} ]} ]" }' https://schemaregistry:8085/subjects/users-value/versions | jq .

     {
       "id": 6
     }

3. View the new schema for the subject ``users-value``. From |c3|, click **MANAGEMENT -> Topics**. Scroll down to and click on the topic `users` and select "SCHEMA".

      .. figure:: images/schema1.png
         :alt: image
   
   You may alternatively request the schema via the command line:

   .. sourcecode:: bash

       docker-compose exec schemaregistry curl -X GET --cert /etc/kafka/secrets/schemaregistry.certificate.pem --key /etc/kafka/secrets/schemaregistry.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt https://schemaregistry:8085/subjects/users-value/versions/1 | jq .

     {
       "subject": "users-value",
       "version": 1,
       "id": 6,
       "schema": "{\"type\":\"record\",\"name\":\"user\",\"fields\":[{\"name\":\"username\",\"type\":\"string\"},{\"name\":\"userid\",\"type\":\"long\"}]}"
     }

4. Use the REST Proxy, which is listening for HTTPS on port 8086, to produce a message to the topic ``users``, referencing schema id ``6``.

   .. sourcecode:: bash

       docker-compose exec restproxy curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" -H "Accept: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{"value_schema_id": 6, "records": [{"value": {"user":{"userid": 1, "username": "Bunny Smith"}}}]}' https://restproxy:8086/topics/users

     {"offsets":[{"partition":1,"offset":0,"error_code":null,"error":null}],"key_schema_id":null,"value_schema_id":6}

5. Use the REST Proxy to consume the above message from the topic ``users``. This is a series of steps.

   .. sourcecode:: bash

     # 5.1 Create consumer instance my_avro_consumer
       docker-compose exec restproxy curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{"name": "my_consumer_instance", "format": "avro", "auto.offset.reset": "earliest"}' https://restproxy:8086/consumers/my_avro_consumer

     # 5.2 Subscribe my_avro_consumer to the `users` topic
       docker-compose exec restproxy curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt --data '{"topics":["users"]}' https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance/subscription

     # 5.3 Get messages for my_avro_consumer subscriptions
     # Note: Issue this command twice due to https://github.com/confluentinc/kafka-rest/issues/432
       docker-compose exec restproxy curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance/records

     # 5.4 Delete the consumer instance my_avro_consumer
       docker-compose exec restproxy curl -X DELETE -H "Content-Type: application/vnd.kafka.v2+json" --cert /etc/kafka/secrets/restproxy.certificate.pem --key /etc/kafka/secrets/restproxy.key --tlsv1.2 --cacert /etc/kafka/secrets/snakeoil-ca-1.crt https://restproxy:8086/consumers/my_avro_consumer/instances/my_consumer_instance


========================
Troubleshooting the demo
========================

1. Verify the status of the Docker containers show ``Up`` state, except for the ``kafka-client`` container which is expected to have ``Exit 0`` state. If any containers are not up, verify in the advanced Docker preferences settings that the memory available to Docker is at least 8 GB (default is 2 GB).

   .. sourcecode:: bash

        docker-compose ps

   Your output should resemble:

   .. sourcecode:: bash

                 Name                        Command               State                              Ports
        ------------------------------------------------------------------------------------------------------------------------------
        connect          /etc/confluent/docker/run                 Up      0.0.0.0:8083->8083/tcp, 9092/tcp                          
        control-center   /etc/confluent/docker/run                 Up      0.0.0.0:9021->9021/tcp, 0.0.0.0:9022->9022/tcp
        elasticsearch    /bin/bash bin/es-docker                   Up      0.0.0.0:9200->9200/tcp, 0.0.0.0:9300->9300/tcp            
        kafka-client     bash -c -a echo Waiting fo ...            Exit 0
        kafka1           /etc/confluent/docker/run                 Up      0.0.0.0:29091->29091/tcp, 0.0.0.0:9091->9091/tcp, 9092/tcp
        kafka2           /etc/confluent/docker/run                 Up      0.0.0.0:29092->29092/tcp, 0.0.0.0:9092->9092/tcp          
        kibana           /bin/sh -c /usr/local/bin/ ...            Up      0.0.0.0:5601->5601/tcp                                    
        ksql-cli         /bin/sh                                   Up                                                                
        ksql-server      /etc/confluent/docker/run                 Up      0.0.0.0:8088->8088/tcp                                    
        replicator       tail -f /dev/null                         Up      8083/tcp, 9092/tcp                                        
        restproxy        /etc/confluent/docker/run                 Up      8082/tcp, 0.0.0.0:8086->8086/tcp                          
        schemaregistry   /etc/confluent/docker/run                 Up      8081/tcp, 0.0.0.0:8085->8085/tcp                          
        zookeeper        /etc/confluent/docker/run                 Up      0.0.0.0:2181->2181/tcp, 2888/tcp, 3888/tcp   

2. To view sample messages for each topic, including
   ``wikipedia.parsed``:

   .. sourcecode:: bash

          ./scripts/consumers/listen.sh

3. If the data streams monitoring appears to stop for the Kafka source
   connector, restart the connect container.

   .. sourcecode:: bash

          docker-compose restart connect

4. If a command that communicates with ZooKeeper appears to be failing with the error ``org.apache.zookeeper.KeeperException$NoAuthException``,
   change the container you are running the command from to be either ``kafka1`` or ``kafka2``.  This is because ZooKeeper is configured for
   `SASL/DIGEST-MD5 <https://docs.confluent.io/current/kafka/authentication_sasl_plain.html#zookeeper>`__, and
   any commands that communicate with ZooKeeper need properties set for ZooKeeper authentication.


========
Teardown
========

1. Stop the consumer group ``app`` to stop consuming from topic
   ``wikipedia.parsed``. Note that the command below stops the consumers
   gracefully with ``kill -15``, so the consumers follow the shutdown
   sequence.

   .. code:: bash

         ./scripts/app/stop_consumer_app_group_graceful.sh

2. Stop the Docker demo, destroy all components and clear all Docker
   volumes.

   .. sourcecode:: bash

          ./scripts/stop.sh

