echo '{"vhost":"/","name":"amq.default","properties":{"delivery_mode":1,"headers":{}},"routing_key":"test_queue","delivery_mode":"1","payload":"{\"transaction\": \"PAYMENT\", \"amount\": \"$125.0\", \"timestamp\": \"'$(date)'\" }","headers":{},"props":{},"payload_encoding":"string"}' |
curl --user guest:guest \
      -X POST -H 'content-type: application/json' \
      --data-binary @-  \
      'http://localhost:15672/api/exchanges/%2F/amq.default/publish'