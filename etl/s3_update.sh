#!/bin/bash -x
#
# find the new blobs and sync them to s3
#
LOCAL_CACHE=/var/www/html/images
S3_BUCKET=s3://omca-media/thumbnails
UPDATE_LOG=/var/www/html/s3_update.log

echo "s3 image update started $(date)" > ${UPDATE_LOG}
cd ~/solr-pipelines || { echo "~/solr-pipelines does not exist" ; exit 1; }

# make a list of the images in the local 'cache'
ls ${LOCAL_CACHE} | perl -pe 's/.jpg//' > s3_already_converted.csv
# make a list of the current public blobs, with their md5 keys
# (the list of public media is created as part of the solr refresh)
gunzip -fk 4solr.omca.media.csv.gz 
cut -f8,16,17 4solr.omca.media.csv | sort | uniq | grep -v blobcsid | grep -v ' rows' > s3_current_blobs.csv
# make a list of the public blobs that are not already in the local 'cache'
cut -f1 s3_current_blobs.csv > s3_c.tmp
diff s3_c.tmp s3_already_converted.csv | grep '<' | cut -c3- > s3_new_blobs.csv
# flesh out the list with the blob md5 key and length
./s3_get_blob_info.sh s3_new_blobs.csv s3_current_blobs.csv > s3_new_blobs_info.csv
# make servable (i.e. smaller) images for the new blobs
time ./s3_resize.sh s3_new_blobs_info.csv ${LOCAL_CACHE} s3_resize_stats.csv
# update the list
cat s3_all_resize_stats.backup s3_resize_stats.csv | sort -u > tmp ; mv tmp s3_all_resize_stats.backup
# sync the new servable images to s3
# (nb: aws credentials need to be set up in the bash shell for this
time aws s3 sync ${LOCAL_CACHE} ${S3_BUCKET}
# make counts
wc -l s3_*.csv s3_all_resize_stats.backup >> ${UPDATE_LOG}
# tidy up
rm s3_c.tmp 4solr.omca.media.csv
gzip -f s3_*.csv
echo "s3 image update ended $(date)" >> ${UPDATE_LOG}

