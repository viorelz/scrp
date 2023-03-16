#!/bin/bash

# TYPO3 specific table
REF_TABLE="tx_realurl_urlencodecache"

# truncate a given table
function empty_table
{
	TABLE=$1
	if [ $(mysql -N -s -e "select count(*) from information_schema.tables where table_schema='$DB' and table_name='$TABLE';")  -eq 1 ]
	then
		mysql  -e "truncate $TABLE" $DB
	else
		echo "Table $DB.$TABLE does not exist"
	fi
}

TABLES_TO_EMPTY=("cache_hash" "cache_imagesizes" "cache_pages" "cachingframework_cache_hash" "cachingframework_cache_hash_tags" "cachingframework_cache_pages" "cachingframework_cache_pagesection" "cachingframework_cache_pagesection_tags" "cachingframework_cache_pages_tags" "tx_realurl_errorlog" "tx_realurl_urldecodecache" "tx_realurl_urlencodecache" "tx_realurl_chashcache" "sys_log")

# find all the TYPO3 databases
DBS=`mysql -Be "select table_schema from information_schema.tables where table_name='$REF_TABLE'" | grep -v table_schema`

#for each database...
for DB in $DBS
do
	#clear the tables
	for TABLE_TO_EMPTY in "${TABLES_TO_EMPTY[@]}"
	do
		empty_table $TABLE_TO_EMPTY
	done
done

echo "Cache cleared"

# delete ENABLE_INSTALL_TOOL forgotten files
/bin/find /var/www -type f -name 'ENABLE_INSTALL_TOOL' -delete
