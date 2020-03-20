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
