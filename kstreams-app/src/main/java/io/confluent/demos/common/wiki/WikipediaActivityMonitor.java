/*
 * Copyright Confluent Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.confluent.demos.common.wiki;

import io.confluent.common.utils.TestUtils;
import io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig;
import io.confluent.kafka.streams.serdes.avro.GenericAvroSerde;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerde;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.kstream.Produced;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

/**
 * A class that builds a Kafka Streams Topology which will process Wikipedia edits from the
 * `wikipedia.parsed` topic and output edit counts grouped by domain
 * to the `wikipedia.parsed.counts-by-domain` topic. The Kafka Streams application can be
 * ran from the `main` provided here which requires a single command line argument,
 * the location to the properties file containing configuration key / value pairs.  The
 * Topology expects Avro inputs of type WikiFeed and produces output of type WikiFeedMetric
 *
 * @see <a href="https://kafka.apache.org/11/javadoc/org/apache/kafka/streams/Topology.html">Topology</a>
 */
class WikipediaActivityMonitor {
  public static final String META = "meta";
  public static final String META_DT = "dt";
  public static final String META_URI = "uri";
  public static final String META_DOMAIN = "domain";
  public static final String USER = "user";
  public static final String COMMENT = "comment";
  public static final String MINOR = "minor";
  public static final String BOT = "bot";
  public static final String PATROLLED = "patrolled";

  public static final String INPUT_TOPIC  = "wikipedia.parsed";
  public static final String OUTPUT_TOPIC = "wikipedia.parsed.count-by-domain";

  private static Properties loadEnvProperties(final String fileName) throws IOException {
    final Properties envProps = new Properties();
    final FileInputStream input = new FileInputStream(fileName);
    envProps.load(input);
    input.close();
    return envProps;
  }

  static Properties overlayDefaultProperties(final Properties baseProperties) {

    final Properties rv = new Properties();
    rv.putAll(baseProperties);

    rv.putIfAbsent(StreamsConfig.APPLICATION_ID_CONFIG,
            "wikipedia-activity-monitor");
    rv.putIfAbsent(StreamsConfig.CLIENT_ID_CONFIG,
            "wikipedia-activity-monitor");
    rv.putIfAbsent(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG,
            "kafka:9092");
    rv.putIfAbsent(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG,
            Serdes.String().getClass());
    rv.putIfAbsent(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG,
            GenericAvroSerde.class);
    rv.putIfAbsent(AbstractKafkaSchemaSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG,
            "http://schema-registry:8081");
    rv.putIfAbsent(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG,
            "earliest");
    rv.putIfAbsent(StreamsConfig.STATE_DIR_CONFIG,
            TestUtils.tempDirectory().getAbsolutePath());

    return rv;
  }

  public static Map<String, Object> propertiesToMap(final Properties props) {
    final Map<String, Object> rv = new HashMap<>();
    final Enumeration<?> names = props.propertyNames();
    while (names.hasMoreElements()) {
      final String key = (String)names.nextElement();
      rv.put(key, props.getProperty(key));
    }
    return rv;
  }

  /**
   * Define the processing topology for the Wikipedia Activity Monitor
   * @param builder The StreamBuilder to apply the topology to
   */
  static void createMonitorStream(final StreamsBuilder builder,
                                  final SpecificAvroSerde<WikiFeedMetric> metricSerde) {

    final Logger logger = LoggerFactory.getLogger(WikipediaActivityMonitor.class);
    builder.<String, GenericRecord>stream(INPUT_TOPIC)
       // INPUT_TOPIC has no key so use domain as the key
       .map((key, value) -> new KeyValue<>(((GenericRecord)value.get(META)).get(META_DOMAIN).toString(), value))
       .filter((key, value) -> !(boolean)value.get(BOT))
       .groupByKey()
       .count()
       .mapValues(WikiFeedMetric::new)
       .toStream()
       .peek((key, value) -> logger.debug("{}:{}", key, value.getEditCount()))
       .to(OUTPUT_TOPIC, Produced.with(Serdes.String(), metricSerde));
  }

  public static void main(final String[] args) throws IOException {

    if (args.length < 1) {
      throw new IllegalArgumentException(
              "This program requires one argument: the path to a properties file");
    }

    final Properties props = overlayDefaultProperties(
            loadEnvProperties(args[0]));

    final SpecificAvroSerde<WikiFeedMetric> metricSerde = new SpecificAvroSerde<>();
    metricSerde.configure(propertiesToMap(props),false);

    final StreamsBuilder builder = new StreamsBuilder();

    createMonitorStream(builder, metricSerde);

    final KafkaStreams streams = new KafkaStreams(builder.build(), props);
    streams.start();

    // Add shutdown hook to respond to SIGTERM and gracefully close Kafka Streams
    Runtime.getRuntime().addShutdownHook(new Thread(streams::close));

  }
}

