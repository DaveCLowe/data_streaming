CREATE SINK CONNECTOR SINK_IMPALA WITH (
    'connector.class'     = 'io.confluent.connect.kudu.KuduSinkConnector',
    'tasks.max'= '1',
    'impala.server'= 'impala',
    'impala.port'= '21050',
    'kudu.database'= 'default',
    'kudu.tablet.replicas'='1',
    'auto.create'= 'true',
    'pk.mode'='record_value',
    'pk.fields'='TX_TYPE,TX_AMOUNT,TX_TIMESTAMP',
    'topics'              = 'TRANSACTIONS',
    'key.converter'       = 'org.apache.kafka.connect.storage.StringConverter',
    'transforms'          = 'dropSysCols',
    'transforms.dropSysCols.type' = 'org.apache.kafka.connect.transforms.ReplaceField$Value',
    'transforms.dropSysCols.blacklist' = 'ROWKEY,ROWTIME',
    'confluent.topic.bootstrap.servers' = 'kafka:9092',
    'impala.ldap.password'='admin',
    'impala.ldap.user'= 'cn=admin,dc=example,dc=org'
  );
