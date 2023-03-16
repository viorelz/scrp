#!/bin/bash

### docs here: https://www.elastic.co/guide/en/elasticsearch/reference/1.3/modules-snapshots.html

# create new snapshot
now=$(date +"%Y_%m_%d-%H-%M");
curl -XPUT "localhost:9200/_snapshot/elasticbkp/${now}?wait_for_completion=true"

# display snapshot sitrep:
curl -XGET "localhost:9200/_snapshot/elasticbkp/_all?pretty"

