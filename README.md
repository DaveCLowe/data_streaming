# Data Streaming
## Introduction
This project creates a collection of containers wrapped via docker-compose to generate a data streaming and transformation pipeline.

Docker will spin up:
- Rabbit AMQP broker
- Kafka Broker
- Kudu Masters (x3)
- Kudu tablet servers. Default of 1, but can scale +- with docker-compose up --scale kudu-tserver=3
- Impala Server (impalad, statestore, catalogd, hive metastore)
- NiFi Server
- Kafka KSQLdb
- Kafka KSQLdb cli host
- Kafka Schema Registry
- Kafka Connect
- Zookeeper
- OpenLDAP directory service

The Docker containers shall form a virtual bridged network named: "streaming".

![Diagram](./assets/img/docker_ds.png)


The data streaming message flow is as follows:
1. Publish JSON message to Rabbit queue
2. Kafka Connect consumes the message from Rabbit and publishes to a Kafka topic
3. Kafka KSQLdb reads from the Kafka topic, performs transformations, and publishes to a secondary topic
4. Kafka Connect (Sink) reads from the secondary topic and publishes to Kudu/Impala with LDAP authentication

### Known gaps and limitations
This is just a POC with security being an afterthought/lacking. There is no crypto or kerberos auth. There is no authorisation. This is just a POC and not fit for production use.

**There is NOT DATA PERSISTANCE!**

### Mapped Ports
- **Service:Local host port:Internal Port**
- ldap:3890:389
- ksqldb-server:18088:8088
- kafka-connect:8083:8083
- kafka:9092:9092
- nifi:8080:8080
- impala:
- schemaregistry:8081:8081
- rabbit:15672:15672
- rabbit mgmt:5672:5672

## Prerequisites
- Docker
- docker-compose
- curl
- jq (Optional, for pretty printing out json payloads)

Ideally, you will also have VS Code and WSL. 

You need to confirm that Docker has at least 8GB of memory available to it:

    docker system info | grep Memory 

Should return a value greater than 8GB - if not, the Kafka stack will probably not work.

## Beginner Guide
### Start the services
Spin up the containers:

	docker-compose up -d

### Configure Rabbit
Create a rabbit queue named test_queue:

	curl --user guest:guest -X PUT -H 'content-type: application/json' --data-binary '{"vhost":"/","name":"test_queue","durable":"true","auto_delete":"false","arguments":{"x-queue-type":"classic"}}' http://localhost:15672/api/queues/%2F/test_queue

What's that whack %2F mean? The default virtual host is called "/", this will need to be URL encoded as "%2f".

Confirm the queue exists. The below will output the queues present:

    curl -s --user guest:guest -X GET -H 'content-type: application/json' http://localhost:15672/api/queues/%2F/ | jq '.[].name '

Publish a message to Rabbit:

TO TEST: 
{\"timestamp\": \"'$(date)'\", \"process_pid\": \"123\", \"process_md5\": \"76fd387fd63d0d3dcd2b691151b70fed\", \"process_name\": \"malware.exe\" }

    echo '{"vhost":"/","name":"amq.default","properties":{"delivery_mode":1,"headers":{}},"routing_key":"test_queue","delivery_mode":"1","payload":"{\"timestamp\": \"'$(date)'\", \"process_pid\": \"123\", \"process_md5\": \"76fd387fd63d0d3dcd2b691151b70fed\", \"process_name\": \"malware.exe\" }","headers":{},"props":{},"payload_encoding":"string"}' | curl --user guest:guest -X POST -H 'content-type: application/json' --data-binary @- http://localhost:15672/api/exchanges/%2F/amq.default/publish


Consume the message to ensure it worked:

    curl --silent --user guest:guest -X POST -H 'content-type: application/json' --data-binary '{"ackmode":"ack_requeue_true","encoding":"auto","count":"10"}' http://localhost:15672/api/queues/%2F/test_queue/get | jq '.[].payload|fromjson'

Check out the Rabbit mgmt UI. Experiment to create familiarity.

(guest/guest)

- http://localhost:15672
- http://localhost:15672/#/queues/%2F/test_queue

### Configure Kafka Connect

![Diagram](./assets/img/kafka_connect-1.png)


Create the Kafka topic by hand to ensure the number of replicas equals 1 as we only have a single broker. **If you're on Windows, replace docker-compose with docker-compose.exe.**

    docker-compose exec kafka kafka-topics --create --topic _confluent-command  --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181

Create the Kafka connect source for Rabbit:

    curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @./connect-rabbitmq/RabbitMQSourceConnector-source.json

Check out the connects json config under connect-rabbitmq/RabbitMQSourceConnector-source.json

    {
    "name": "RabbitMQSourceConnector",
    "config": {
        "connector.class": "io.confluent.connect.rabbitmq.RabbitMQSourceConnector",
        "tasks.max": "2",
        "kafka.topic": "test_topic",
        "rabbitmq.queue": "test_queue",
        "rabbitmq.username": "guest",
        "rabbitmq.password": "guest",
        "rabbitmq.host": "rabbitmq",
        "rabbitmq.virtual.host": "/",
        "confluent.topic.bootstrap.servers": "kafka:9092",
        "value.converter": "org.apache.kafka.connect.converters.ByteArrayConverter",
        "key.converter": "org.apache.kafka.connect.storage.StringConverter"
    }
}

One thing to pay attention to is “tasks.max”: “2", here we are setting the number of tasks we want to run. One task will run on each worker - but for us, both will run on the single broker. We could set this value higher to have more Tasks running on each broker. Tasks do all the work under the hood, they are responsible in this case for consuming from RabbitMQ and producing to Kafka. As tasks are single jobs, we can scale tasks when needed. More information about Tasks can be found here: https://docs.confluent.io/current/connect/concepts.html#connect-tasks.

Check out the status of the connector to ensure it is healthy.

    docker-compose exec kafka-connect bash -c 'curl -s http://localhost:8083/connectors/RabbitMQSourceConnector/status'

Should return something like:

    {"name":"RabbitMQSourceConnector","connector":{"state":"RUNNING","worker_id":"kafka-connect:8083"},"tasks":[{"id":0,"state":"RUNNING","worker_id":"kafka-connect:8083"},{"id":1,"state":"RUNNING","worker_id":"kafka-connect:8083"}],"type":"source"}%  

## Checkpoint 1

At this point, all messages submitted to the rabbit queue "test_queue" will be consumed by Kafka Connect and published onto the Kafka topic "test_topic".

Send a few more messages to Rabbit and consume the Kafka topic "test_topic" to see the results.

    docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic test_topic --from-beginning

You should see something like:

    {"timestamp": "Tue Mar 24 15:17:19 AEDT 2020", "process_pid": "123", "process_md5": "76fd387fd63d0d3dcd2b691151b70fed", "process_name": "malware.exe" }

## KSQLdb

Time for some KSQLdb action.  https://ksqldb.io/overview.html

Start ksqlDB's interactive CLI:

    docker-compose exec ksqldb-cli ksql http://ksqldb-server:8088

Dump out the test_topic contents:

    ksql> PRINT 'test_topic' FROM BEGINNING;
    ctrl+c


Create a stream (https://docs.ksqldb.io/en/latest/concepts/collections/streams/). 

A stream essentially associates a schema with an underlying Kafka topic.

    CREATE STREAM from_rabbit (timestamp VARCHAR,
                      process_pid VARCHAR,
                      process_md5 VARCHAR, process_name VARCHAR) WITH (KAFKA_TOPIC='test_topic', VALUE_FORMAT='JSON');

Reset your offset to earliest, and read from this new stream using SQL:

    SET 'auto.offset.reset' = 'earliest';
    SELECT timestamp, process_pid, process_md5, process_name  FROM from_rabbit EMIT CHANGES;

Now, let's create a transformed stream to a new Kafka topic which we'll later publish to Kudu.

Develop/test the SQL:

    SELECT PROCESS_MD5 AS MD5,
         SPLIT(PROCESS_NAME,'.')[1] AS FILE_EXTENSION,
         PROCESS_NAME, CAST(PROCESS_PID AS INT) AS PID,
         TIMESTAMP AS TS_TIMESTAMP
    FROM from_rabbit WHERE TIMESTAMP IS NOT NULL EMIT CHANGES;

Turn this into a stream/topic as avro:

    CREATE STREAM PROCESS_EVENTS WITH (VALUE_FORMAT='AVRO') AS SELECT PROCESS_MD5 AS MD5,
         SPLIT(PROCESS_NAME,'.')[1] AS FILE_EXTENSION,
         PROCESS_NAME, CAST(PROCESS_PID AS INT) AS PID,
         TIMESTAMP AS TS_TIMESTAMP
    FROM from_rabbit WHERE TIMESTAMP IS NOT NULL EMIT CHANGES;

Now read the new topic:

    SELECT * FROM PROCESS_EVENTS EMIT CHANGES;

## Checkpoint 2
We are now using KSQL on Kafka to read JSON from one topic (test_topic), transform the data, and write messages back to a new topic (PROCESS_EVENTS) in avro format.

## Kafka Connect - Kudu Sink

We now want every record published to the PROCESS_EVENTS topic to be stored in Kudu.

TO do this, we use a Kafka Connect Sink (not a source) for Kudu over Impala. This appears to be a licenced Confluent product but free to use for a short period of time (30 days?).

The Kudu sink requires LDAP authentication, hence the bundling of OpenLDAP within this solution.

From your ksql cli shell, create the Kudu sink:

    CREATE SINK CONNECTOR SINK_IMPALA WITH (
    'connector.class'     = 'io.confluent.connect.kudu.KuduSinkConnector',
    'tasks.max'= '1',
    'impala.server'= 'impala',
    'impala.port'= '21050',
    'kudu.database'= 'default',
    'kudu.tablet.replicas'='1',
    'auto.create'= 'true',
    'pk.mode'='record_value',
    'pk.fields'='TS_TIMESTAMP,MD5,PROCESS_NAME',
    'topics'              = 'PROCESS_EVENTS',
    'key.converter'       = 'org.apache.kafka.connect.storage.StringConverter',
    'transforms'          = 'dropSysCols',
    'transforms.dropSysCols.type' = 'org.apache.kafka.connect.transforms.ReplaceField$Value',
    'transforms.dropSysCols.blacklist' = 'ROWKEY,ROWTIME',
    'confluent.topic.bootstrap.servers' = 'kafka:9092',
    'impala.ldap.password'='admin',
    'impala.ldap.user'= 'cn=admin,dc=example,dc=org'
  );

Publish messages to Rabbit, and tail logs on the Impala container.

You can also run an impala-shell:

    ➜ docker-compose exec kudu-impala impala-shell -i localhost:21000 -l -u cn=admin,dc=example,dc=org --ldap_password_cmd="echo -n admin" --auth_creds_ok_in_clear << EOF use default; show tables; select * from process_events; EOF


