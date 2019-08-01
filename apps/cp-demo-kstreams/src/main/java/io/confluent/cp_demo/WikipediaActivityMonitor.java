package io.confluent.cp_demo;

import io.confluent.common.utils.TestUtils;
import io.confluent.kafka.serializers.AbstractKafkaAvroSerDeConfig;
import io.confluent.kafka.streams.serdes.avro.GenericAvroSerde;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import java.util.Properties;

public class WikipediaActivityMonitor {
   public static final String CREATEDAT = "createdat";
   public static final String WIKIPAGE = "wikipage";
   public static final String CHANNEL = "channel";
   public static final String USERNAME = "username";
   public static final String COMMITMESSAGE = "commitmessage";
   public static final String BYTECHANGE = "bytechange";
   public static final String DIFFURL = "diffurl";
   public static final String ISNEW = "isnew";
   public static final String ISMINOR = "isminor";
   public static final String ISBOT = "isbot";
   public static final String ISUNPATROLLED = "isunpatrolled";

   public static String INPUT_TOPIC  = "wikipedia.parsed";
   public static String OUPTUT_TOPIC = "wikipedia.parsed.count-by-channel";

   static Properties getStreamsConfiguration(final String bootstrapServers, final String schemaRegistryUrl) {
      final Properties streamsConfiguration = new Properties();
      // Give the Streams application a unique name.  The name must be unique in the Kafka cluster
      // against which the application is run.
      streamsConfiguration.put(StreamsConfig.APPLICATION_ID_CONFIG, "wikipedia-activity-monitor");
      streamsConfiguration.put(StreamsConfig.CLIENT_ID_CONFIG, "wikipedia-activity-monitor");
      // Where to find Kafka broker(s).
      streamsConfiguration.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
      // Specify default (de)serializers for record keys and for record values.
      streamsConfiguration.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG,
              Serdes.String().getClass().getName());
      streamsConfiguration.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG,
              GenericAvroSerde.class);
      streamsConfiguration.put(AbstractKafkaAvroSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG,
              schemaRegistryUrl);
      streamsConfiguration.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
      // Use a temporary directory for storing state, which will be automatically removed after the test.
      streamsConfiguration.put(StreamsConfig.STATE_DIR_CONFIG,
              TestUtils.tempDirectory().getAbsolutePath());
      return streamsConfiguration;
   }
   /**
    * Define the processing topology for the Wikipedia Activity Monitor
    * @param builder The StreamBuilder to apply the topology to
    */
   static void createMonitorStream(final StreamsBuilder builder) {
      builder.<String, GenericRecord>stream(INPUT_TOPIC)
         .filter((key, value) -> !(boolean)value.get(ISBOT))
         .groupByKey()
         .count()
         .toStream().to(OUPTUT_TOPIC);
   }
   public static void main(final String[] args) {
      final String bootstrapServers = args.length > 0 ? args[0] : "kafka1:10091,kafka2:10091";
      final String schemaRegistryUrl = args.length > 1 ? args[1] : "https://schemaregistry:8085";

      final StreamsBuilder builder = new StreamsBuilder();
      createMonitorStream(builder);
      final KafkaStreams streams = new KafkaStreams(
         builder.build(),
         getStreamsConfiguration(bootstrapServers, schemaRegistryUrl));
      streams.start();

      // Add shutdown hook to respond to SIGTERM and gracefully close Kafka Streams
      Runtime.getRuntime().addShutdownHook(new Thread(streams::close));
   }
}
