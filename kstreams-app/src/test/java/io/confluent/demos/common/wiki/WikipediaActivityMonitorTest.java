package io.confluent.demos.common.wiki;

import io.confluent.kafka.schemaregistry.avro.AvroSchema;
import io.confluent.kafka.schemaregistry.client.SchemaRegistryClient;
import io.confluent.kafka.schemaregistry.testutil.MockSchemaRegistry;
import io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig;
import io.confluent.kafka.serializers.KafkaAvroSerializer;
import io.confluent.kafka.streams.serdes.avro.SpecificAvroSerde;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.common.serialization.*;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.TopologyTestDriver;
import org.apache.kafka.streams.TestInputTopic;
import org.apache.kafka.streams.TestOutputTopic;
import org.junit.Test;

import java.util.stream.Collectors;
import java.util.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;

/**
 * Basic unit test functions for the `WikipediaActivityMonitor` class.  Uses the
 * MockScheamRegistry class from Confluent and the TopologyTestDriver from
 * Kafka Streams.
 *
 * @see io.confluent.kafka.schemaregistry.testutil.MockSchemaRegistry
 * @see org.apache.kafka.streams.TopologyTestDriver
 */
public class WikipediaActivityMonitorTest {

    private final GenericRecord testRecord;

    private static final String SCHEMA_REGISTRY_SCOPE = WikipediaActivityMonitorTest.class.getName();
    private final SchemaRegistryClient schemaRegistryClient = MockSchemaRegistry
            .getClientForScope(SCHEMA_REGISTRY_SCOPE);

    private static final String MOCK_SCHEMA_REGISTRY_URL = "mock://" + SCHEMA_REGISTRY_SCOPE;

    public WikipediaActivityMonitorTest() {
        testRecord = buildTestRecord(1564664987360L, "Apache Kafka",
                "#en.wikipedia", "jdoe", "fun new content", 500,
                "http://diff", false, true, false, false)
                .orElseThrow(() -> new RuntimeException("schema could not be loaded"));
        registerSchema(schemaRegistryClient, WikiEdit.SCHEMA$, WikipediaActivityMonitor.INPUT_TOPIC);
    }

    private static void registerSchema(final SchemaRegistryClient schemaRegistryClient,
                                       final Schema s,
                                       final String topic) {
        try {
            schemaRegistryClient.register(topic + "-value", new AvroSchema(s));
        } catch (final Exception ignored) { }
    }
    private static GenericRecord with(final GenericRecord from, final String name, final Object value) {
        from.put(name, value);
        return from;
    }
    private static Optional<GenericRecord> cloneRecord(final GenericRecord from) {
        return buildTestRecord(
                (Long)from.get(WikipediaActivityMonitor.CREATEDAT),
                (String)from.get(WikipediaActivityMonitor.WIKIPAGE),
                (String)from.get(WikipediaActivityMonitor.CHANNEL),
                (String)from.get(WikipediaActivityMonitor.USERNAME),
                (String)from.get(WikipediaActivityMonitor.COMMITMESSAGE),
                (int)from.get(WikipediaActivityMonitor.BYTECHANGE),
                (String)from.get(WikipediaActivityMonitor.DIFFURL),
                (boolean)from.get(WikipediaActivityMonitor.ISNEW),
                (boolean)from.get(WikipediaActivityMonitor.ISMINOR),
                (boolean)from.get(WikipediaActivityMonitor.ISBOT),
                (boolean)from.get(WikipediaActivityMonitor.ISUNPATROLLED));
    }
    private static Optional<GenericRecord> buildTestRecord(
            final Long createdAt,
            final String wikipage,
            final String channel,
            final String username,
            final String commitMessage,
            final int byteChange,
            final String diffUrl,
            final boolean isNew,
            final boolean isMinor,
            final boolean isBot,
            final boolean isUnpatrolled
    ) {
      final GenericRecord record = new GenericData.Record(WikiEdit.SCHEMA$);
      record.put(WikipediaActivityMonitor.CREATEDAT, createdAt);
      record.put(WikipediaActivityMonitor.WIKIPAGE, wikipage);
      record.put(WikipediaActivityMonitor.CHANNEL, channel);
      record.put(WikipediaActivityMonitor.USERNAME, username);
      record.put(WikipediaActivityMonitor.COMMITMESSAGE, commitMessage);
      record.put(WikipediaActivityMonitor.BYTECHANGE, byteChange);
      record.put(WikipediaActivityMonitor.DIFFURL, diffUrl);
      record.put(WikipediaActivityMonitor.ISNEW, isNew);
      record.put(WikipediaActivityMonitor.ISMINOR, isMinor);
      record.put(WikipediaActivityMonitor.ISBOT, isBot);
      record.put(WikipediaActivityMonitor.ISUNPATROLLED, isUnpatrolled);
      return Optional.of(record);
    }

    @Test
    public void testWikiActivityMonitor() {

        final Properties tempProps = new Properties();
        tempProps.putIfAbsent(AbstractKafkaSchemaSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG,
               MOCK_SCHEMA_REGISTRY_URL);
        final Properties finalProps = WikipediaActivityMonitor.overlayDefaultProperties(tempProps);

        final SpecificAvroSerde<WikiFeedMetric> metricSerde = new SpecificAvroSerde<>();
        metricSerde.configure(WikipediaActivityMonitor.propertiesToMap(finalProps), false);

        final StreamsBuilder builder = new StreamsBuilder();
        WikipediaActivityMonitor
                .createMonitorStream(builder, metricSerde);
        final TopologyTestDriver testDriver = new TopologyTestDriver(builder.build(), finalProps);

        final TestInputTopic<String, Object>
            inputTopic = testDriver.createInputTopic(WikipediaActivityMonitor.INPUT_TOPIC, new StringSerializer(), new KafkaAvroSerializer(schemaRegistryClient));
        final TestOutputTopic<String, WikiFeedMetric>
            outputTopic = testDriver.createOutputTopic(WikipediaActivityMonitor.OUTPUT_TOPIC, new StringDeserializer(), metricSerde.deserializer());

        final List<GenericRecord> inputValues = new ArrayList<>();
        cloneRecord(testRecord)
                .map(c -> with(
                            with(c, WikipediaActivityMonitor.ISBOT, true),
                            WikipediaActivityMonitor.CHANNEL, "#en.wikipedia"))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.CHANNEL, "#fr.wikipedia"))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.CHANNEL, "#en.wikipedia"))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.CHANNEL, "#fr.wikipedia"))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(
                        with(c, WikipediaActivityMonitor.ISBOT, true),
                        WikipediaActivityMonitor.CHANNEL, "#en.wikipedia"))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.CHANNEL, "#en.wikipedia"))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.CHANNEL, "#fr.wikipedia"))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.CHANNEL, "#fr.wikipedia"))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.CHANNEL, "#en.wikipedia"))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.CHANNEL, "#uk.wikipedia"))
                .ifPresent(inputValues::add);

        inputTopic.pipeKeyValueList(inputValues
                        .stream()
                        .map(v -> new KeyValue<>(
                                (String) v.get(WikipediaActivityMonitor.CHANNEL),
                                (Object) v))
                        .collect(Collectors.toList()));

        List<WikiFeedMetric> counts = outputTopic.readKeyValuesToList()
            .stream().map(kv -> kv.value).collect(Collectors.toList());

        assertThat((long)counts.size())
            .isEqualTo(inputValues
                    .stream()
                    .filter(gr -> !(boolean) gr.get(WikipediaActivityMonitor.ISBOT)).count());

        assertThat(counts).extracting("channel", "editCount")
                .containsExactly(
                        tuple("#fr.wikipedia", 1L),
                        tuple("#en.wikipedia", 1L),
                        tuple("#fr.wikipedia", 2L),
                        tuple("#en.wikipedia", 2L),
                        tuple("#fr.wikipedia", 3L),
                        tuple("#fr.wikipedia", 4L),
                        tuple("#en.wikipedia", 3L),
                        tuple("#uk.wikipedia", 1L));

        try {
            testDriver.close();
        } catch (final RuntimeException e) {
            // https://issues.apache.org/jira/browse/KAFKA-6647 causes exception when executed in Windows, ignoring it
            // Logged stacktrace cannot be avoided
            System.out.println("Ignoring exception, test failing in Windows due this exception:" + e.getLocalizedMessage());
        }
        MockSchemaRegistry.dropScope(SCHEMA_REGISTRY_SCOPE);
    }
}
