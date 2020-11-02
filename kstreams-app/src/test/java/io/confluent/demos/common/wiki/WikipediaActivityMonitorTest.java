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
        testRecord = buildTestRecord(
                buildMeta(1602598008000L, "Apache Kafka", "commons.wikimedia.org"),
                "jdoe",
                "fun new content",
                true,
                false,
                false)
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
    private static GenericRecord buildMeta(final Long timestamp, final String uri, final String domain) {
        final GenericRecord rv = new GenericData.Record(KsqlDataSourceSchema_META.SCHEMA$);
        rv.put(WikipediaActivityMonitor.META_DT, timestamp);
        rv.put(WikipediaActivityMonitor.META_URI, uri);
        rv.put(WikipediaActivityMonitor.META_DOMAIN, domain);
        return rv;
    }
    private static GenericRecord cloneMeta(GenericRecord from) {
        return buildMeta(
                (Long)from.get(WikipediaActivityMonitor.META_DT),
                (String)from.get(WikipediaActivityMonitor.META_URI),
                (String)from.get(WikipediaActivityMonitor.META_DOMAIN));
    }
    private static Optional<GenericRecord> cloneRecord(final GenericRecord from) {
        return buildTestRecord(
                cloneMeta((GenericRecord)from.get(WikipediaActivityMonitor.META)),
                (String)from.get(WikipediaActivityMonitor.USER),
                (String)from.get(WikipediaActivityMonitor.COMMENT),
                (boolean)from.get(WikipediaActivityMonitor.MINOR),
                (boolean)from.get(WikipediaActivityMonitor.BOT),
                (boolean)from.get(WikipediaActivityMonitor.PATROLLED));
    }
    private static Optional<GenericRecord> buildTestRecord(
            final GenericRecord metadata,
            final String user,
            final String comment,
            final boolean minor,
            final boolean bot,
            final boolean patrolled
    ) {
      final GenericRecord record = new GenericData.Record(WikiEdit.SCHEMA$);
      record.put(WikipediaActivityMonitor.META, metadata);
      record.put(WikipediaActivityMonitor.USER, user);
      record.put(WikipediaActivityMonitor.COMMENT, comment);
      record.put(WikipediaActivityMonitor.MINOR, minor);
      record.put(WikipediaActivityMonitor.BOT, bot);
      record.put(WikipediaActivityMonitor.PATROLLED, patrolled);
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

        final GenericRecord metadata1 = new GenericData.Record(KsqlDataSourceSchema_META.SCHEMA$);
        metadata1.put("domain", "commons.wikimedia.org");
        final GenericRecord metadata2 = new GenericData.Record(KsqlDataSourceSchema_META.SCHEMA$);
        metadata2.put("domain", "en.wikipedia.org");

        cloneRecord(testRecord)
                .map(c -> with(
                            with(c, WikipediaActivityMonitor.BOT, true),
                            WikipediaActivityMonitor.META, metadata1))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.META, metadata1))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.META, metadata2))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.META, metadata2))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(
                        with(c, WikipediaActivityMonitor.BOT, true),
                            WikipediaActivityMonitor.META, metadata2))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.META, metadata1))
                .ifPresent(inputValues::add);

        inputTopic.pipeKeyValueList(inputValues
                        .stream()
                        .map(v -> new KeyValue<>(
                                (String) null,
                                (Object) v))
                        .collect(Collectors.toList()));

        List<WikiFeedMetric> counts = outputTopic.readKeyValuesToList()
            .stream().map(kv -> kv.value).collect(Collectors.toList());

        assertThat((long)counts.size())
            .isEqualTo(inputValues
                    .stream()
                    .filter(gr -> !(boolean) gr.get(WikipediaActivityMonitor.BOT)).count());

        assertThat(counts).extracting("domain", "editCount")
                .containsExactly(
                        tuple(metadata1.get(WikipediaActivityMonitor.META_DOMAIN).toString(), 1L),
                        tuple(metadata2.get(WikipediaActivityMonitor.META_DOMAIN).toString(), 1L),
                        tuple(metadata2.get(WikipediaActivityMonitor.META_DOMAIN).toString(), 2L),
                        tuple(metadata1.get(WikipediaActivityMonitor.META_DOMAIN).toString(), 2L));

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
