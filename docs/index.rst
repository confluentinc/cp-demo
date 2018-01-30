.. _cp-demo:

Monitoring Kafka streaming ETL deployments
==========================================

This demo shows you how to monitor Kafka streaming ETL deployments using :ref:`Confluent Control Center <control_center>`.
You can follow along with the playbook and video tutorials. All of the components in |CP| have security enabled end-to-end.

.. contents:: Contents
    :local:
    :depth: 2


========
Overview
========

The use case is a stream processing on live edits to real Wikipedia
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
cluster. This demo uses `KSQL <https://github.com/confluentinc/ksql>`__
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

============
Installation
============

Follow along with the `Demo 1: Install + Run <https://www.youtube.com/watch?v=a4B5Oer1j2A>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/a4B5Oer1j2A" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>


**Prerequisites:**

-  Docker version 17.06.1-ce
-  Docker Compose version 1.14.0 with Docker Compose file format 2.1
-  Java version 1.8.0_92
-  MacOS 10.12
-  git
-  jq

1. Clone the `cp-demo GitHub repository <https://github.com/confluentinc/cp-demo>`__:

   .. sourcecode:: bash

     $ git clone https://github.com/confluentinc/cp-demo

2. In the advanced Docker preferences settings, increase the memory
   available to Docker to at least 8 GB (default is 2 GB).

========
Run demo
========

1. From the ``cp-demo`` directory, generate certs used for security.

   .. sourcecode:: bash

      $ (cd scripts/security && ./certs-create.sh)

2. Start the demo. It will take about 2 minutes for all containers to
   start and for |c3| GUI to be ready.

   .. sourcecode:: bash

      $ docker-compose up -d

3. Verify the status of the Docker containers show ``Up`` state, except
   for the ``kafka-client`` container which is expected to have
   ``Exit 0`` state. If any containers are not up, verify in the
   advanced Docker preferences settings that the memory available to
   Docker is at least 8 GB (default is 2 GB).

   .. sourcecode:: bash

      $ docker-compose ps

   Your output should resemble:

   .. sourcecode:: bash

                 Name                        Command               State                              Ports
        ------------------------------------------------------------------------------------------------------------------------------
        cpdemo_connect_1          /etc/confluent/docker/run        Up       0.0.0.0:8083->8083/tcp, 9092/tcp
        cpdemo_control-center_1   /etc/confluent/docker/run        Up       0.0.0.0:9021->9021/tcp
        cpdemo_elasticsearch_1    /bin/bash bin/es-docker          Up       0.0.0.0:9200->9200/tcp, 0.0.0.0:9300->9300/tcp
        cpdemo_kafka-client_1     bash -c -a echo Waiting fo ...   Exit 0
        cpdemo_kafka1_1           /etc/confluent/docker/run        Up       0.0.0.0:29091->29091/tcp, 0.0.0.0:9091->9091/tcp, 9092/tcp
        cpdemo_kafka2_1           /etc/confluent/docker/run        Up       0.0.0.0:29092->29092/tcp, 0.0.0.0:9092->9092/tcp
        cpdemo_kibana_1           /bin/sh -c /usr/local/bin/ ...   Up       0.0.0.0:5601->5601/tcp
        cpdemo_ksql-cli_1         perl -e while(1){ sleep 99 ...   Up       0.0.0.0:9098->9098/tcp
        cpdemo_schemaregistry_1   /etc/confluent/docker/run        Up       8081/tcp, 0.0.0.0:8082->8082/tcp
        cpdemo_zookeeper_1        /etc/confluent/docker/run        Up       0.0.0.0:2181->2181/tcp, 2888/tcp, 3888/tcp


4. Wait till |c3| is running fully. Verify it is
   ready when the logs show the following event:

   .. sourcecode:: bash

        $ docker-compose logs -f control-center | grep -e "Started NetworkTrafficServerConnector"
        control-center_1       | [2017-09-06 16:37:33,133] INFO Started NetworkTrafficServerConnector@26a529dc{HTTP/1.1}{0.0.0.0:9021} (org.eclipse.jetty.server.NetworkTrafficServerConnector)

5. Run the setup which customizes the Kafka cluster, Kafka source
   and sink connectors, Elasticsearch, and Kibana dashboard.

   .. sourcecode:: bash

      $ ./scripts/setup.sh

6. Use Google Chrome to view the |c3| GUI at
   http://localhost:9021.

   Click on the top right button that shows the current date, and change
   ``Last 4 hours`` to ``Last 30 minutes``.

7. View the data in the Kibana dashboard at
   http://localhost:5601/app/kibana#/dashboard/Wikipedia

========
Playbook
========

Tour of |c3|
--------------------------------

Follow along with the `Demo 2: Tour <https://youtu.be/D9nzAxxIv7A>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/D9nzAxxIv7A" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>

1. **Monitoring –> System Health**: |c3| landing
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




2. **Management –> Kafka Connect**: |c3| uses
   the Kafka Connect API to manage `Kafka
   connectors <https://docs.confluent.io/current/control-center/docs/connect.html>`__.

   -  Kafka Connect **Sources** tab shows the connectors
      ``wikipedia-irc`` and ``replicate-topic``. Click ``Edit`` to see
      the details of the connector configuration and custom transforms.

      .. figure:: images/connect_source.png
   



   -  Kafka Connect **Sinks** tab shows the connector
      ``elasticsearch-ksql``. Click ``Edit`` to see the details of the
      connector configuration and custom transforms.

      .. figure:: images/connect_sink.png
         :alt: image



3. **Monitoring –> Data Streams –> Message Delivery**: hover over
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



4. **Management –> Topics –> Topic Information**: For a given topic,
   click on the three dots ``...`` next to the topic name and click on
   ``View details``. View which brokers are leaders for which partitions
   and the number of consumer groups currently consuming from this
   topic. Click on the boxed consumer group count to select a consumer
   group for which to monitor its data streams and jump to it.

5. **Monitoring –> System Health**: to identify bottlenecks, you can
   see a breakdown of produce and fetch latencies through the entire
   `request
   lifecycle <https://docs.confluent.io/current/control-center/docs/systemhealth.html>`__.
   Click on the line graph in the ``Request latency`` chart. The request
   latency values can be shown at the median, 95th, 99th, or 99.9th
   percentile. Depending on where the bottlenecks are, you can tune your
   brokers and clients appropriately.

   .. figure:: images/request_latencies.png
      :alt: image



KSQL
----

Follow along with the `Demo 3: KSQL <https://youtu.be/U_ntFVXWBPc>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/U_ntFVXWBPc" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
    </div>

In this demo, KSQL is configured with
`properties <https://github.com/confluentinc/cp-demo/blob/master/scripts/ksql/ksqlproperties>`__ to connect to the secured
Kafka cluster and is already running queries.

1. Run the KSQL CLI to get more information on the queries, streams, and
   tables.

   .. sourcecode:: bash

      $ docker-compose exec ksql-cli ksql-cli remote http://localhost:8080

   For example, you can run these commands:

   - ``ksql> SHOW QUERIES;``
   - ``ksql> DESCRIBE WIKIPEDIABOT;``
   - ``ksql> SELECT * FROM WIKIPEDIABOT LIMIT 3;``
   - ``ksql> DESCRIBE EN_WIKIPEDIA_GT_1;``
   - ``ksql> SELECT * FROM EN_WIKIPEDIA_GT_1 LIMIT 3;``

   *By default when you run a ``SELECT`` in KSQL it will return new data
   that is added. If you want to view data already existing in the topic
   run this first (once per session):*

   .. sourcecode:: bash

        SET 'auto.offset.reset' = 'earliest';

2. **Monitoring –> Data Streams –> Message Delivery**: KSQL queries are materialized in |c3| as consumer groups with names ``ksql_query_``. To correlate these consumer groups to the actual KSQL query, note the query ID in the output of:

   .. sourcecode:: bash

      $ docker-compose exec ksql-cli ksql-cli remote http://localhost:8080 --exec "show queries;"

3. **Monitoring –> Data Streams –> Message Delivery**: graphs for
   consumer groups ``EN_WIKIPEDIA_GT_1_COUNTS-consumer`` and
   ``ksql_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS`` are displaying data at
   intervals instead of smoothly like the other consumer groups. This is
   because |c3| displays data based on message
   timestamps, and this particular stream of a data is a tumbling window
   with a window size of 5 minutes. Thus all its message timestamps are
   marked to the beginning of each 5-minute window and this is why the
   latency for these streams appears to be high. Kafka streaming
   tumbling windows are working as designed and |c3|
   is reporting them accurately.

   .. figure:: images/tumbling_window.png
      :alt: image



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

        $ ./scripts/app/start_consumer_app.sh 1

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

        $ ./scripts/app/start_consumer_app.sh 2

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

Follow along with the `Demo 5: Slow Consumers <https://youtu.be/HPIskKJjmNU>`_ video.

.. raw:: html

    <div style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; height: auto;">
        <iframe src="https://www.youtube.com/embed/HPIskKJjmNU" frameborder="0" allowfullscreen style="position: absolute; top: 0; left: 0; width: 75%; height: 75%;"></iframe>
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

        $ ./scripts/app/throttle_consumer.sh 1 add

   .. note:: you are running a Docker demo environment with all services
   running on one host, which you would never do in production.
   Depending on your system resource availability, sometimes applying
   the quota may stall the consumer
   (`KAFKA-5871 <https://issues.apache.org/jira/browse/KAFKA-5871>`__),
   thus you may need to adjust the quota rate. See the
   ``./scripts/app/throttle_consumer.sh`` script for syntax on modifying
   the quota rate.

   -  If consumer group ``app`` does not increase latency, decrease the
      quota rate
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

6. Click on the fetch request latency line graph to see a breakdown of
   produce and fetch latencies through the entire `request
   lifecycle <https://docs.confluent.io/current/control-center/docs/systemhealth.html>`__.
   The middle number does not necessarily equal the sum of the
   percentiles of individual segments because it is the total percentile
   latency.

7. Remove the consumption quota for the consumer. Latency for
   ``consumer_app_1`` recovers to steady state values.

   .. sourcecode:: bash

        $ ./scripts/app/throttle_consumer.sh 1 delete

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

2. Let this consumer group run for 2 minutes until Control Center stream
   monitoring shows the consumer group ``app`` with steady consumption.

3. Stop the consumer group ``app`` to stop consuming from topic
   ``wikipedia.parsed``. Note that the command below stops the consumers
   gracefully with ``kill -15``, so the consumers follow the shutdown
   sequence.

   .. sourcecode:: bash

        $ ./scripts/app/stop_consumer_app_group_graceful.sh

4. Wait for 2 minutes to let messages continue to be written to the
   topics for a while, without being consumed by the consumer group
   ``app``. Notice the red bar which highlights that during the time
   window when the consumer group was stopped, there were some messages
   produced but not consumed. These messages are not missing, they are
   just not consumed because the consumer group stopped.

5. Reset the offset of the consumer group ``app`` by shifting 200
   offsets backwards. The offset reset tool must be run when the
   consumer is completely stopped. Offset values in output shown below
   will vary.

   .. sourcecode:: bash

       $ docker-compose exec kafka1 kafka-consumer-groups \
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

        $ ./scripts/app/start_consumer_app.sh 1
        $ ./scripts/app/start_consumer_app.sh 2

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

2. Let this consumer group run for 2 minutes until Control Center stream
   monitoring shows the consumer group ``app`` with steady consumption.

3. Stop the consumer group ``app`` to stop consuming from topic
   ``wikipedia.parsed``. Note that the command below stops the consumers
   ungracefully with ``kill -9``, so the consumers did not follow the
   shutdown sequence.

   .. sourcecode:: bash

        $ ./scripts/app/stop_consumer_app_group_ungraceful.sh

4. Wait for 2 minutes to let messages continue to be written to the
   topics for a while, without being consumed by the consumer group
   ``app``. Notice the red bar which highlights that during the time
   window when the consumer group was stopped, there were some messages
   produced but not consumed. These messages are not missing, they are
   just not consumed because the consumer group stopped.

5. Wait for another few minutes and notice that the bar graph changes
   and there is a
   `herringbone <https://docs.confluent.io/current/control-center/docs/monitoring.html#missing-metrics-data>`__
   pattern to indicate that perhaps the consumer group stopped
   ungracefully.

6. Reset the offset of the consumer group ``app`` by setting it to
   latest offset. The offset reset tool must be run when the consumer is
   completely stopped. Offset values in output shown below will vary.

   .. sourcecode:: bash

       $ docker-compose exec kafka1 kafka-consumer-groups \
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

        $ ./scripts/app/start_consumer_app.sh 1
        $ ./scripts/app/start_consumer_app.sh 2

8. Let this consumer group run for 2 minutes until Control Center stream
   monitoring shows the consumer group ``app`` with steady consumption.
   Notice that during the time period that the consumer group ``app``
   was not running, no produced messages are shown as delivered.

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

        $ docker-compose stop kafka2

2. After a few minutes, observe the System Health shows the broker count
   has gone down from 2 to 1, and there are many under replicated
   partitions.

3. View topic details to see that there are out of sync replicas on
   broker 2.

4. Restart the Docker container running Kafka broker 2.

   .. sourcecode:: bash

        $ docker-compose start kafka2

5. After about a minute, observe the System Health view in Confluent
   Control Center. The broker count has recovered to 2, and the topic
   partitions are back to reporting no under replicated partitions.

6. Click on the broker count ``2`` inside the circle to view when the
   broker counts changed.

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

5. View the Alert history to see that this trigger happened and caused
   an alert.

Replicator
----------

Confluent Replicator copies data from a source Kafka cluster to a
destination Kafka cluster. The source and destination clusters are
typically different clusters, but in this demo, Replicator is doing
intra-cluster replication, *i.e.*, the source and destination Kafka
clusters are the same. As with the rest of the components in the
solution, Confluent Replicator is also configured with security.

1. **Monitoring –> Data Streams –> Message Delivery**: monitor
   throughput and latency of Confluent Replicator in the Data streams
   monitoring view. Replicator is a Kafka Connect source connector and
   has a corresponding consumer group ``connect-replicator``.

   .. figure:: images/replicator_consumer_group.png
      :alt: image



2. **Management –> Topics**: scroll down to view the topics called
   ``wikipedia.parsed`` (Replicator is consuming data from this topic)
   and ``wikipedia.parsed.replica`` (Replicator is copying data to this
   topic). Click on ``Consumer Groups`` for the topic
   ``wikipedia.parsed`` and observe that one of the consumer groups is
   called ``connect-replicator``.

   .. figure:: images/replicator_topic_info.png


3. **Management –> Kafka Connect**: pause the Replicator connector
   by pressing the pause icon in the top right. This will stop
   consumption for the related consumer group.

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

All the components in this demo are enabled with many `security
features <https://docs.confluent.io/current/security.html>`__:

-  `SSL <https://docs.confluent.io/current/kafka/authentication_ssl.html>`__
   for encryption, except for ZooKeeper which does not support SSL
-  `SASL/PLAIN <https://docs.confluent.io/current/kafka/authentication_sasl_plain.html>`__
   for authentication, except for ZooKeeper
-  `Authorization <https://docs.confluent.io/current/kafka/authorization.html>`__.
   If a resource has no associated ACLs, then users are not allowed to
   access the resource, except super users
-  `HTTPS for Schema
   Registry <https://docs.confluent.io/current/schema-registry/docs/security.html>`__

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
components authenticate as ``client``. Per the broker configuration
parameter ``super.users``, as it is set in this demo, the only users
that can communicate with the cluster are those that authenticate as
``broker`` or ``client``, or users that connect via the ``PLAINTEXT``
port (their username is ``ANONYMOUS``). All other users are not
authorized to communicate with the cluster.

1. Verify the ports on which the Kafka brokers are listening with the
   following command, and they should match the table shown below:

   .. sourcecode:: bash

        $ docker-compose logs kafka1 | grep "Registered broker 1"
        $ docker-compose logs kafka2 | grep "Registered broker 2"

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
           $ docker-compose exec kafka1 kafka-consumer-groups --list --bootstrap-server kafka1:10091

   #.  Communicate with brokers via the SASL_SSL port, and SASL_SSL
       parameters configured via the ``--command-config`` argument for
       command line tools or ``--consumer.config`` for
       kafka-console-consumer.

       .. sourcecode:: bash

            # SASL_SSL port with SASL_SSL parameters
            $ docker-compose exec kafka1 kafka-consumer-groups --list --bootstrap-server kafka1:9091 \
               --command-config /etc/kafka/secrets/client_without_interceptors.config

   #.  If you try to communicate with brokers via the SASL_SSL port but
       don’t specify the SASL_SSL parameters, it will fail

       .. sourcecode:: bash

            # SASL_SSL port without SASL_SSL parameters
            $ docker-compose exec kafka1 kafka-consumer-groups --list --bootstrap-server kafka1:9091

       Your output should resemble:

       .. sourcecode:: bash

            Error: Executing consumer group command failed due to Request
            METADATA failed on brokers List(kafka1:9091 (id: -1 rack: null))


3. Verify the super users are configured for the authenticated users
   ``broker``, ``client``, and unauthenticated ``PLAINTEXT``.

   .. sourcecode:: bash

       $ docker-compose logs kafka1 | grep SUPER_USERS

   Your output should resemble:

   .. sourcecode:: bash

         KAFKA_SUPER_USERS=User:client;User:broker;User:ANONYMOUS 

4. Verify that a user ``client`` which authenticates via SASL can
   consume messages from topic ``wikipedia.parsed``:

   .. sourcecode:: bash

        $ ./scripts/consumers/listen_wikipedia.parsed.sh SASL

5. Verify that a user which authenticates via SSL cannot consume
   messages from topic ``wikipedia.parsed``. It should fail with an exception.

   .. sourcecode:: bash

       $ ./scripts/consumers/listen_wikipedia.parsed.sh SSL

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
        $ docker-compose logs kafka1 | grep kafka.authorizer.logger


   Your output should resemble:

   .. sourcecode:: bash

        [2018-01-12 21:13:18,454] INFO Principal = User:CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US is Denied Operation = Describe from host = 172.23.0.7 on resource = Topic:wikipedia.parsed (kafka.authorizer.logger) [2018-01-12
        21:13:18,464] INFO Principal = User:CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US is Denied Operation = Describe from host = 172.23.0.7 on resource = Group:test (kafka.authorizer.logger) 

7. Add an ACL that authorizes user
   ``CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US``, and then
   view the updated ACL configuration.

   .. sourcecode:: bash

    $ docker-compose exec connect /usr/bin/kafka-acls \
        --authorizer-properties zookeeper.connect=zookeeper:2181 \
        --add --topic wikipedia.parsed \
        --allow-principal User:CN=client,OU=TEST,O=CONFLUENT,L=PaloAlto,ST=Ca,C=US \
        --operation Read --group test

    $ docker-compose exec connect /usr/bin/kafka-acls \
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

        $ ./scripts/consumers/listen_wikipedia.parsed.sh SSL


========================
Troubleshooting the demo
========================

1. To view sample messages for each topic, including
   ``wikipedia.parsed``:

   .. sourcecode:: bash

        $ ./scripts/consumers/listen.sh

2. If the data streams monitoring appears to stop for the Kafka source
   connector, restart the connect container.

   .. sourcecode:: bash

        $ docker-compose restart connect

========
Teardown
========

1. Stop the consumer group ``app`` to stop consuming from topic
   ``wikipedia.parsed``. Note that the command below stops the consumers
   gracefully with ``kill -15``, so the consumers follow the shutdown
   sequence.

   .. code:: bash

       $ ./scripts/app/stop_consumer_app_group_graceful.sh

2. Stop the Docker demo, destroy all components and clear all Docker
   volumes.

   .. sourcecode:: bash

        $ ./scripts/reset_demo.sh

