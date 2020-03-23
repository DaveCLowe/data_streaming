You can create the connector via KSQL, but I did it manually.
It should be something like:
CREATE SOURCE CONNECTOR rabbit_source WITH (
  'connector.class'= 'io.confluent.connect.rabbitmq.RabbitMQSourceConnector',
        'tasks.max'= '2',
        'kafka.topic'= 'test_topic',
        'rabbitmq.queue'= 'test_queue',
        'rabbitmq.username'= 'guest',
        'rabbitmq.password'= 'guest',
        'rabbitmq.host'= 'rabbitmq',
        'rabbitmq.virtual.host'= '/',
        'confluent.topic.bootstrap.servers'= 'kafka:9092',
        'value.converter'= 'org.apache.kafka.connect.converters.ByteArrayConverter',
        'key.converter'= 'org.apache.kafka.connect.storage.StringConverter');


The rest of these commands can be executed via ksql-cli

docker exec -it ksqldb-cli ksql http://ksqldb-server:8088

ksql> PRINT 'test_topic' FROM BEGINNING;

ksql> CREATE STREAM rabbit (transaction VARCHAR,
                      amount VARCHAR,
                      timestamp VARCHAR)
  WITH (KAFKA_TOPIC='test_topic', VALUE_FORMAT='JSON');


SET 'auto.offset.reset' = 'earliest';
SELECT transaction, amount, timestamp FROM rabbit EMIT CHANGES;

CREATE STREAM TRANSACTIONS WITH (VALUE_FORMAT='AVRO') AS
  SELECT TRANSACTION AS TX_TYPE,
         SUBSTRING(AMOUNT,1,1) AS CURRENCY,
         CAST(SUBSTRING(AMOUNT,2,LEN(AMOUNT)-1) AS DECIMAL(9,2)) AS TX_AMOUNT,
         TIMESTAMP AS TX_TIMESTAMP
    FROM rabbit2
   WHERE TIMESTAMP IS NOT NULL
    EMIT CHANGES;

SELECT TX_TYPE, CURRENCY, TX_AMOUNT, TX_TIMESTAMP FROM TRANSACTIONS EMIT CHANGES;

CREATE SINK CONNECTOR SINK_IMPALA WITH (
    'connector.class'     = 'io.confluent.connect.kudu.KuduSinkConnector',
    'tasks.max'= '1',
    'impala.server'= 'kudu-impala',
    'impala.port'= '21050',
    'kudu.database'= 'default',
    'auto.create'= 'true',
    'pk.mode'='record_value',
    'pk.fields'='id',
    'topics'              = 'TRANSACTIONS',
    'key.converter'       = 'org.apache.kafka.connect.storage.StringConverter',
    'transforms'          = 'dropSysCols',
    'transforms.dropSysCols.type' = 'org.apache.kafka.connect.transforms.ReplaceField$Value',
    'transforms.dropSysCols.blacklist' = 'ROWKEY,ROWTIME'
  );

