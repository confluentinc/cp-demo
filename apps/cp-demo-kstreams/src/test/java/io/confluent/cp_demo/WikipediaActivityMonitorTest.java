package io.confluent.cp_demo;

import io.confluent.kafka.schemaregistry.client.SchemaRegistryClient;
import io.confluent.kafka.schemaregistry.testutil.MockSchemaRegistry;
import io.confluent.kafka.serializers.KafkaAvroSerializer;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.record.TimestampType;
import org.apache.kafka.common.serialization.*;
import org.apache.kafka.streams.KeyValue;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.TopologyTestDriver;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import java.util.*;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

public class WikipediaActivityMonitorTest {


    private TopologyTestDriver testDriver;
    private final GenericRecord testRecord;
    private final Optional<Schema> schema = loadSchema();

    private static final String SCHEMA_REGISTRY_SCOPE = WikipediaActivityMonitorTest.class.getName();
    final SchemaRegistryClient schemaRegistryClient = MockSchemaRegistry
            .getClientForScope(SCHEMA_REGISTRY_SCOPE);
    private static final String MOCK_SCHEMA_REGISTRY_URL = "mock://" + SCHEMA_REGISTRY_SCOPE;

    public WikipediaActivityMonitorTest() {
        testRecord = buildTestRecord(1564664987360L, "Apache Kafka",
                "#en.wikipedia", "jdoe", "fun new content", 500,
                "http://diff", false, true, false, false)
                .orElseThrow(() -> new RuntimeException("schema could not be loaded"));
        schema.ifPresent(s -> registerSchema(schemaRegistryClient, s, WikipediaActivityMonitor.INPUT_TOPIC));
    }

    private static void registerSchema(final SchemaRegistryClient schemaRegistryClient, final Schema s, final String topic) {
        try {
            schemaRegistryClient.register(topic + "-value", s);
        } catch (final Exception ex) { }
    }
    private static <K, V> void produceKeyValuesSynchronously(final String topic,
                                                     final List<KeyValue<K, V>> records,
                                                     final TopologyTestDriver topologyTestDriver,
                                                     final Serializer<K> keySerializer,
                                                     final Serializer<V> valueSerializer,
                                                     final long timestamp) {
        for (final KeyValue<K, V> entity : records) {
            final ConsumerRecord<byte[], byte[]> consumerRecord = new ConsumerRecord<>(
                    topic,
                    0,
                    0,
                    timestamp,
                    TimestampType.CREATE_TIME,
                    ConsumerRecord.NULL_CHECKSUM,
                    ConsumerRecord.NULL_SIZE,
                    ConsumerRecord.NULL_SIZE,
                    keySerializer.serialize(topic, entity.key),
                    valueSerializer.serialize(topic, entity.value)
            );
            topologyTestDriver.pipeInput(consumerRecord);
        }
    }
    private static <K, V> List<KeyValue<K, V>> drainStreamOutput(final String topic,
                                                         final TopologyTestDriver topologyTestDriver,
                                                         final Deserializer<K> keyDeserializer,
                                                         final Deserializer<V> valueDeserializer) {
        final List<KeyValue<K, V>> results = new LinkedList<>();
        while (true) {
            final ProducerRecord<K, V> record = topologyTestDriver.readOutput(topic, keyDeserializer, valueDeserializer);
            if (record == null) {
                break;
            } else {
                results.add(new KeyValue<>(record.key(), record.value()));
            }
        }
        return results;
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
    private static Optional<Schema> loadSchema() {
        try {
            return Optional.of(new Schema.Parser()
                .parse(WikipediaActivityMonitorTest.class
                        .getResourceAsStream("/avro/io/confluent/cp_demo/WikiFeedUpdate.avsc")));
        } catch (final Exception e) {
            return Optional.empty();
        }
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
        Schema schema = null;
        try {
            schema = new Schema.Parser().parse(WikipediaActivityMonitorTest.class.getResourceAsStream("/avro/io/confluent/cp_demo/WikiFeedUpdate.avsc"));
        } catch (final Exception e) {}
        if (schema == null)
            return Optional.empty();
        else {
            final GenericRecord record = new GenericData.Record(schema);
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
    }

    @Before
    public void setup() {

        final StreamsBuilder builder = new StreamsBuilder();
        WikipediaActivityMonitor.createMonitorStream(builder);
        testDriver = new TopologyTestDriver(builder.build(),
            WikipediaActivityMonitor.getStreamsConfiguration("localhost:9092", MOCK_SCHEMA_REGISTRY_URL));
    }

    @After
    public void tearDown() {
        try {
            testDriver.close();
        } catch (final RuntimeException e) {
            // https://issues.apache.org/jira/browse/KAFKA-6647 causes exception when executed in Windows, ignoring it
            // Logged stacktrace cannot be avoided
            System.out.println("Ignoring exception, test failing in Windows due this exception:" + e.getLocalizedMessage());
        }
        MockSchemaRegistry.dropScope(SCHEMA_REGISTRY_SCOPE);
    }

    @Test
    public void testWikiActivityMonitor() {

        final List<GenericRecord> inputValues = new ArrayList<>();
        inputValues.add(testRecord);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.ISBOT, true))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.CHANNEL, "#fr.wikipedia"))
                .ifPresent(inputValues::add);
        cloneRecord(testRecord)
                .map(c -> with(c, WikipediaActivityMonitor.CHANNEL, "#fr.wikipedia"))
                .ifPresent(inputValues::add);

        produceKeyValuesSynchronously(
                WikipediaActivityMonitor.INPUT_TOPIC,
                inputValues.stream().map(v -> new KeyValue<>((String) v.get(WikipediaActivityMonitor.CHANNEL), (Object) v)).collect(Collectors.toList()),
                testDriver,
                new StringSerializer(),
                new KafkaAvroSerializer(schemaRegistryClient),
                0L
        );

        final List<Long> counts = drainStreamOutput(
                WikipediaActivityMonitor.OUPTUT_TOPIC,
                testDriver,
                new StringDeserializer(),
                new LongDeserializer()
        ).stream().map(kv -> kv.value).collect(Collectors.toList());

        assertThat((long)counts.size())
            .isEqualTo(inputValues.stream().filter(gr -> !(boolean)gr.get(WikipediaActivityMonitor.ISBOT)).count());

        assertThat(counts.get(0) == 1);
        assertThat(counts.get(1) == 2);
    }
}
