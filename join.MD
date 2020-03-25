Craete the topic which holds the osinfo events:

    docker-compose exec kafka kafka-topics --create --topic host_info  --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181

Pump in an osinfo event:

    cat host_info.json | docker-compose exec -T kafka kafka-console-producer --broker-list kafka:9092 --topic host_info


# https://github.com/confluentinc/ksql/issues/1405


Create a stream over the raw JSON on the host_info topic:

     CREATE STREAM HOST_INFO_STREAM (HOSTNAME VARCHAR, USER VARCHAR, IP VARCHAR, HOST_ID VARCHAR, EVENT_TIMESTAMP VARCHAR) WITH (kafka_topic='host_info', value_format='json');

Create a second keyed stream over this stream by hostname:

    CREATE STREAM HOST_INFO_STREAM_BY_HOSTNAME AS SELECT * FROM HOST_INFO_STREAM WHERE hostname is not null PARTITION BY HOSTNAME;

Create a ksql table over the stream:

    CREATE TABLE HOST_INFO_TABLE (hostname VARCHAR, USER VARCHAR, IP VARCHAR, HOST_ID VARCHAR, EVENT_TIMESTAMP VARCHAR) WITH (kafka_topic='HOST_INFO_STREAM_BY_HOSTNAME',key='HOSTNAME', value_format='json');

Ensure the streams exist for the incoming process events. You might have done this earlier, if so - jump to "create a keyed by hostname stream over the stream":

    CREATE STREAM proces_raw_in (timestamp VARCHAR,
                      process_pid VARCHAR,
                      process_md5 VARCHAR, process_name VARCHAR, hostname VARCHAR) WITH (KAFKA_TOPIC='test_topic', VALUE_FORMAT='JSON');

Create the transformed process stream:
    CREATE STREAM PROCESS_EVENTS WITH (VALUE_FORMAT='AVRO') AS SELECT PROCESS_MD5 AS MD5,
         SPLIT(PROCESS_NAME,'.')[1] AS FILE_EXTENSION,
         PROCESS_NAME, CAST(PROCESS_PID AS INT) AS PID,
         TIMESTAMP AS TS_TIMESTAMP, HOSTNAME
    FROM proces_raw_in WHERE TIMESTAMP IS NOT NULL EMIT CHANGES;

**Create a keyed by hostname stream over the stream**:

    CREATE STREAM PROCESS_EVENTS_BY_HOSTNAME AS SELECT * FROM PROCESS_EVENTS PARTITION BY HOSTNAME;

Finally, create the joined stream:

    CREATE STREAM enriched_process AS
  SELECT p.HOSTNAME, p.PROCESS_NAME, p.PID, p.FILE_EXTENSION, h.user, h.ip
  FROM PROCESS_EVENTS_BY_HOSTNAME  p
  JOIN HOST_INFO_TABLE  h
  ON p.HOSTNAME = h.HOSTNAME EMIT CHANGES;
