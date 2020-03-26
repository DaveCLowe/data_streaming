
CREATE STREAM STR_PROCSTART_BASE (publish_timestamp VARCHAR, cb_server VARCHAR, command_line VARCHAR, computer_name VARCHAR, event_type VARCHAR, expect_followon_w_md5 VARCHAR, md5 VARCHAR, parent_create_time INT, parent_md5 VARCHAR, parent_path VARCHAR, parent_process_guid VARCHAR, path VARCHAR, pid INT, process_guid VARCHAR, sensor_id INT, timestamp INT, type VARCHAR, username VARCHAR) WITH (kafka_topic='test_topic', value_format='json') ; 
CREATE STREAM STR_PROCSTART_BY_COMPUTER_NAME AS SELECT * FROM STR_PROCSTART_BASE WHERE COMPUTER_NAME is not null PARTITION BY COMPUTER_NAME;
CREATE STREAM STR_OSINFO_BASE (cb_server VARCHAR, computer_name VARCHAR, event_type VARCHAR, ip_address VARCHAR, agent_id VARCHAR, timestamp VARCHAR, type VARCHAR, OSArchitecture VARCHAR, OSLanguage INT, Manufacturer VARCHAR, Caption VARCHAR, InstallDate VARCHAR, CurrentTimeZone INT, LastBootUpTime VARCHAR, LocalDateTime VARCHAR, OSType INT, Version VARCHAR, BootDevice VARCHAR, BuildNumber INT, CodeSet INT, CountryCode INT) WITH (kafka_topic='osinfo_raw', value_format='json') ;
CREATE STREAM STR_OSINFO_BY_COMPUTER_NAME AS SELECT * FROM STR_OSINFO_BASE WHERE COMPUTER_NAME is not null PARTITION BY COMPUTER_NAME;
CREATE TABLE TBL_OSINFO_BY_COMPUTER_NAME (cb_server VARCHAR, computer_name VARCHAR, event_type VARCHAR, ip_address VARCHAR, agent_id VARCHAR, timestamp VARCHAR, type VARCHAR, OSArchitecture VARCHAR, OSLanguage INT, Manufacturer VARCHAR, Caption VARCHAR, InstallDate VARCHAR, CurrentTimeZone INT, LastBootUpTime VARCHAR, LocalDateTime VARCHAR, OSType INT, Version VARCHAR, BootDevice VARCHAR, BuildNumber INT, CodeSet INT, CountryCode INT) WITH (kafka_topic='STR_OSINFO_BY_COMPUTER_NAME',key='computer_name', value_format='json');
CREATE STREAM STR_MODULELOAD_BASE (cb_server VARCHAR, computer_name VARCHAR, event_type VARCHAR, md5 VARCHAR, path VARCHAR, pid INT, process_guid VARCHAR, sensor_id INT, timestamp INT, type VARCHAR ) WITH (kafka_topic='moduleload_raw', value_format='json') ;  
CREATE STREAM STR_MODULELOAD_BY_COMPUTER_NAME AS SELECT * FROM STR_MODULELOAD_BASE WHERE COMPUTER_NAME is not null PARTITION BY COMPUTER_NAME;
CREATE STREAM STR_PROCSTART_ENRICHED AS SELECT p.COMMAND_LINE, p.COMPUTER_NAME, p.MD5 as proc_md5, p.PATH as proc_path, p.PID, p.PROCESS_GUID, p.TIMESTAMP as ts_procstart, p.USERNAME, p.PARENT_PATH, h.IP_ADDRESS, h.CAPTION, h.VERSION FROM STR_PROCSTART_BY_COMPUTER_NAME p JOIN TBL_OSINFO_BY_COMPUTER_NAME h ON p.COMPUTER_NAME = h.COMPUTER_NAME EMIT CHANGES;


CREATE STREAM STR_MODLOAD_ENRICHED AS
  SELECT e.COMMAND_LINE, e.p_COMPUTER_NAME, e.proc_md5, e.proc_path, e.PID, e.PROCESS_GUID, e.ts_procstart, e.USERNAME, e.PARENT_PATH, e.IP_ADDRESS, e.CAPTION, e.VERSION, m.MD5 as mod_md5, m.PATH as mod_path
  FROM STR_PROCSTART_ENRICHED e
  INNER JOIN STR_MODULELOAD_BY_COMPUTER_NAME m WITHIN 2 HOURS
  ON e.p_computer_name = m.computer_name where e.process_guid = m.process_guid
  EMIT CHANGES;