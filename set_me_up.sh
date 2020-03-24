#!/bin/bash
set -e
curl --user guest:guest -X PUT -H 'content-type: application/json' --data-binary '{"vhost":"/","name":"test_queue","durable":"true","auto_delete":"false","arguments":{"x-queue-type":"classic"}}' http://localhost:15672/api/queues/%2F/test_queue
curl -s --user guest:guest -X GET -H 'content-type: application/json' http://localhost:15672/api/queues/%2F/ | jq '.[].name '
echo '{"vhost":"/","name":"amq.default","properties":{"delivery_mode":1,"headers":{}},"routing_key":"test_queue","delivery_mode":"1","payload":"{\"transaction\": \"PAYMENT\", \"amount\": \"$125.0\", \"timestamp\": \"'$(date)'\" }","headers":{},"props":{},"payload_encoding":"string"}' | curl --user guest:guest -X POST -H 'content-type: application/json' --data-binary @- http://localhost:15672/api/exchanges/%2F/amq.default/publish
curl --silent --user guest:guest -X POST -H 'content-type: application/json' --data-binary '{"ackmode":"ack_requeue_true","encoding":"auto","count":"10"}' http://localhost:15672/api/queues/%2F/test_queue/get | jq '.[].payload|fromjson'
docker-compose exec kafka kafka-topics --create --topic _confluent-command  --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @./connect-rabbitmq/RabbitMQSourceConnector-source.json
docker-compose exec kafka-connect bash -c 'curl -s http://localhost:8083/connectors/RabbitMQSourceConnector/status'
##curl --silent --user guest:guest \\n        -X POST -H 'content-type: application/json' \\n        --data-binary '{"ackmode":"ack_requeue_true","encoding":"auto","count":"10"}' \\n        'http://localhost:15672/api/queues/%2F/test_queue/get' | jq '.[].payload|fromjson'\n
