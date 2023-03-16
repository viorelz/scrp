#!/bin/bash
#
# Restore a snapshot from our repository
SNAPSHOT=123

# We need to close the index first
curl -XPOST "localhost:9200/my_index/_close"

# Restore the snapshot we want
curl -XPOST "http://localhost:9200/_snapshot/my_backup/$SNAPSHOT/_restore" -d '{
 "indices": "my_index"
}'

# Re-open the index
curl -XPOST 'localhost:9200/my_index/_open'


