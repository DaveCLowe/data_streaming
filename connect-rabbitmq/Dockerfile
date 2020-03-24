FROM confluentinc/cp-kafka-connect-base:5.4.1
# RUN confluent-hub install --no-prompt confluentinc/kafka-connect-rabbitmq:latest
# RUN confluent-hub install --no-prompt confluentinc/kafka-connect-kudu:latest
ADD ./confluentinc-kafka-connect-kudu-1.0.1/ /usr/share/confluent-hub-components/confluentinc-kafka-connect-kudu/
ADD ./confluentinc-kafka-connect-rabbitmq-1.2.0/ /usr/share/confluent-hub-components/confluentinc-kafka-connect-rabbitmq/