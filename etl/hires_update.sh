#!/bin/bash -x
#
# insert the hires image info into the solr refresh files
#
SOLR_CSV_FILE=$1
S3_BUCKET=s3://omca-media/hires

echo "hires image update started $(date)"
cd ~/solr-pipelines || { echo "~/solr-pipelines does not exist" ; exit 1; }

# make a list of the hires images in the aws cdn
aws s3 ls ${S3_BUCKET} --recursive > hires.csv
perl -pe 's/^.*?hires\/(.*?)\.\w+$/\1/' hires.csv | sort -r > hires_objectnumbers.csv
echo "hires image update ended $(date)"
