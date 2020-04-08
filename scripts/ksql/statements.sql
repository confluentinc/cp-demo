CREATE STREAM wikipedia WITH (kafka_topic='wikipedia.parsed', value_format='AVRO');
CREATE STREAM wikipedianobot AS SELECT * FROM wikipedia WHERE isbot <> true;
CREATE STREAM wikipediabot AS SELECT * FROM wikipedia WHERE isbot = true;
CREATE TABLE en_wikipedia_gt_1 AS SELECT username, wikipage, count(*) AS COUNT FROM wikipedia WINDOW TUMBLING (size 300 second) WHERE channel = '#en.wikipedia' GROUP BY username, wikipage HAVING count(*) > 1;
CREATE STREAM en_wikipedia_gt_1_stream (USERNAME string, WIKIPAGE string, COUNT bigint) WITH (kafka_topic='EN_WIKIPEDIA_GT_1', value_format='AVRO');
CREATE STREAM en_wikipedia_gt_1_counts AS SELECT * FROM en_wikipedia_gt_1_stream where ROWTIME is not null;
