CREATE STREAM wikipedia WITH (kafka_topic='wikipedia.parsed', value_format='AVRO');
CREATE STREAM wikipedianobot AS SELECT * FROM wikipedia WHERE 'bot.boolean' <> 'true';
CREATE STREAM wikipediabot AS SELECT * FROM wikipedia WHERE 'bot.boolean' = 'true';
CREATE TABLE en_wikipedia_gt_1 AS SELECT 'user.string' AS username, 'meta.uri.string' AS URI, count(*) AS COUNT FROM wikipedia WINDOW TUMBLING (size 300 second) WHERE 'meta.domain.string' = 'commons.wikimedia.org' GROUP BY 'user.string', 'meta.uri.string' HAVING count(*) > 1;
CREATE STREAM en_wikipedia_gt_1_stream (USERNAME string, URI string, COUNT bigint) WITH (kafka_topic='EN_WIKIPEDIA_GT_1', value_format='AVRO');
CREATE STREAM en_wikipedia_gt_1_counts AS SELECT * FROM en_wikipedia_gt_1_stream where ROWTIME is not null;
