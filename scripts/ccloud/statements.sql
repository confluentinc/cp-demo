CREATE STREAM wikipedia WITH (kafka_topic='wikipedia.parsed', value_format='AVRO');
CREATE STREAM wikipedianobot AS SELECT *, (length->new - length->old) AS BYTECHANGE FROM wikipedia WHERE bot = false AND length IS NOT NULL AND length->new IS NOT NULL AND length->old IS NOT NULL;
