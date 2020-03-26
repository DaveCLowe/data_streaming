statements=$(< create_streams.sql) && \
    echo '{"ksql":"'$statements'", "streamsProperties": {}}' | \
        curl -X "POST" "http://localhost:18088/ksql" \
             -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
             -d @- | \
        jq