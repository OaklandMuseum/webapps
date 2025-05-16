#!/bin/bash
source /var/www/venv/bin/activate
# extract metadata and load into netxdb
echo "Data Source Sync starting `date`"
cd ~webapps/webapps/etc/dss2022
echo "copying 4solr.omca.internal.csv.gz and extracting and massaging columns..."
cp ~webapps/solr-pipelines/4solr.omca.internal.csv.gz .
gunzip -f 4solr.omca.internal.csv.gz
cut -f1-11,14- 4solr.omca.internal.csv > tmp.csv
# nb: even though the columns are listed out of order, cut outputs them in order. caveat coder!
cut -f 3,4,6,15,16,18,22,26,27,28,29,30,31,33,34,35,36,37,43,44,45,46,47,55,63,79 tmp.csv > netx-extract.csv
python convert.py netx-extract.csv netxview.csv
echo "`wc -l netxview.csv` rows (including header) extracted from '4solr file' containing `wc -l 4solr.omca.internal.csv | cut -f1 -d" "` lines"
psql -h 10.161.2.192 -U netx -d netxdb -f create-netxview.sql
echo "netxview table recreated. copying data..."

psql -h 10.161.2.192 -U netx -d netxdb -f copy.sql
rm 4solr.omca.internal.csv  netx-extract.csv netxview.csv tmp.csv
echo "Data Source Sync ended `date`"
