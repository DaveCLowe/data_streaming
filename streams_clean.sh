curl -s -X "POST" http://localhost:18088/ \
    -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
    -d '{"ksql": "DESCRIBE PROCESS_EVENTS;"}' \ |
    jq '.[].sourceDescription.writeQueries[].id' | \
 xargs -Iq1 curl -X "POST" http://localhost:18088/ \
          -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
          -d '{"ksql": "TERMINATE 'q1';"}' | jq
