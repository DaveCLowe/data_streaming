echo '{"vhost":"/","name":"amq.default","properties":{"delivery_mode":1,"headers":{}},"routing_key":"test_queue","delivery_mode":"1","payload":"{ \"publish_timestamp\": \"'$(date +%s)'\",\"cb_server\": \"cbserver\", \"command_line\": \"Global\\\\\\\\UsGthrFltPipeMssGthrPipe253\", \"computer_name\": \"JASON-WIN81-VM\", \"event_type\": \"proc\", \"expect_followon_w_md5\": false, \"md5\": \"D6021013D7C4E248AEB8BED12D3DCC88\", \"parent_create_time\": 1447440685, \"parent_md5\": \"79227C1E2225DE455F365B607A6D46FB\", \"parent_path\": \"c:\\\\\\\\windows\\\\\\\\system32\\\\\\\\searchindexer.exe\", \"parent_process_guid\": \"00000001-0000-0af4-01d1-1e444bf4c3dd\", \"path\": \"c:\\\\\\\\windows\\\\\\\\system32\\\\\\\\searchprotocolhost.exe\", \"pid\": 1972, \"process_guid\": \"00000001-0000-07b4-01d1-209a100bc217\", \"sensor_id\": 1, \"timestamp\": 1447697423, \"type\": \"ingress.event.procstart\", \"username\": \"SYSTEM\"}","headers":{},"props":{},"payload_encoding":"string"}' |
curl --user guest:guest \
      -X POST -H 'content-type: application/json' \
      --data-binary @-  \
      'http://localhost:15672/api/exchanges/%2F/amq.default/publish'