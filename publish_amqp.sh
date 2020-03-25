echo '{"vhost":"/","name":"amq.default","properties":{"delivery_mode":1,"headers":{}},"routing_key":"test_queue","delivery_mode":"1","payload":"{\"timestamp\": \"'$(date)'\", \"process_pid\": \"123\", \"process_md5\": \"76fd387fd63d0d3dcd2b691151b70fed\", \"process_name\": \"malware.exe\", \"hostname\": \"WIN7-DESKTOP\" }","headers":{},"props":{},"payload_encoding":"string"}' |
curl --user guest:guest \
      -X POST -H 'content-type: application/json' \
      --data-binary @-  \
      'http://localhost:15672/api/exchanges/%2F/amq.default/publish'