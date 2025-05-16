#!/bin/bash -x
date
##############################################################################
# move the current set of extracts to temp (thereby saving the previous run, just in case)
##############################################################################
mv 4solr.*.csv.gz /tmp
##############################################################################
# while most of this script is already tenant-specific, many of the commands
# are shared between the different scripts; having them be as similar as possible
# eases maintenance. ergo, the TENANT parameter
# password expected in .pgpass
##############################################################################
TENANT=$1
SERVER="localhost sslmode=prefer"
USERNAME="reader_${TENANT}"
DATABASE="${TENANT}_domain_${TENANT}"
CONNECTSTRING="host=$SERVER dbname=$DATABASE"
##############################################################################
# extract metadata and media info from CSpace
##############################################################################
# run the "media query"
# cleanup newlines and crlf in data, then switch record separator.
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f media.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' > 4solr.${TENANT}.media.csv &
##############################################################################
# start the stitching process: extract the "basic" data
##############################################################################
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f basic-public.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' > public.csv &
time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f basic-internal.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' > internal.csv &
wait
##############################################################################
# stitch this together with the results of the rest of the "subqueries"
# there are several query patterns which based on a couple of parameters
# will pull out multivalued fields, aggregate them, and spit them out with
# the top level object csid
#
# the patterns are in the template*.sql files
# the parameters are in the type*.txt files
##############################################################################
for TYPE in 1 2 3 4 5
do
  for var in `cat type${TYPE}.txt`
  do
    XTABLE=`echo $var | cut -d ',' -f 1`
    FIELD=`echo $var | cut -d ',' -f 2`
    perl -pe "s/XTABLE/${XTABLE}/g;s/FIELD/${FIELD}/g" template${TYPE}.sql > temp.sql
    time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f temp.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' > temp1.csv
    for CORE in public internal
    do
      time python3 join.py ${CORE}.csv temp1.csv > temp2.csv
      mv temp2.csv ${CORE}.csv
      # keep this intermediate file around for debugging, until the end of the run
      cp temp1.csv t${TYPE}.${var}.csv
    done
  done
done
##############################################################################
# these queries are special, the dont fit the patterns above
##############################################################################
for i in {1..20}
do
 if [ -f part$i.sql ]; then
   time psql -F $'\t' -R"@@" -A -U $USERNAME -d "$CONNECTSTRING" -f part$i.sql | perl -pe 's/[\r\n]/ /g;s/\@\@/\n/g' > part$i.csv
   time python3 join.py internal.csv part$i.csv > temp1.csv &
   time python3 join.py public.csv part$i.csv > temp2.csv &
   wait
   mv temp1.csv internal.csv
   mv temp2.csv public.csv
 fi
done
##############################################################################
#  compute a boolean: hascoords = yes/no
##############################################################################
# perl setCoords.pl 35 < d6.csv > d6a.csv
##############################################################################
#  mark the 16 'first' objects for the blacklight portal (public core only)
##############################################################################
python3 add_firsts.py public.csv temp.csv
# TODO: why is add_firsts.py adding an extra newline to the output? fix!
perl -pe 's/\r//g' temp.csv > public.csv
##############################################################################
# add the blob and other media flags to the rest of the metadata
# and we want to recover and use our "special" solr-friendly header, which got buried
##############################################################################
for CORE in public internal
do
  # check that all rows have the same number of fields as the header
  export NUMCOLS=`grep csid ${CORE}.csv | awk '{ FS = "\t" ; print NF}'`
  time awk -v NUMCOLS=$NUMCOLS '{ FS = "\t" ; if (NF == 0+NUMCOLS) print }' ${CORE}.csv | perl -pe 's/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;' > 4solr.${TENANT}.base.${CORE}.csv &
  time awk -v NUMCOLS=$NUMCOLS '{ FS = "\t" ; if (NF != 0+NUMCOLS) print }' ${CORE}.csv | perl -pe 's/\\/\//g' > errors.${CORE}.csv &
  wait
  # merge media and metadata files (done in perl ... very complicated to do in SQL)
  time perl mergeObjectsAndMedia.pl 4solr.${TENANT}.media.csv 4solr.${TENANT}.base.${CORE}.csv hires_objectnumbers.csv "https://d6jfg2a0yiapu.cloudfront.net/hires"  > d6.csv
  # recover the solr header and put it back at the top of the file
  grep csid d6.csv > header4Solr.csv
  # generate solr schema <copyField> elements, just in case.
  # also generate parameters for POST to solr (to split _ss fields properly)
  ./genschema.sh ${CORE}
  grep -v csid d6.csv > d8.csv
  cat header4Solr.csv d8.csv | perl -pe 's/␥/|/g' > d9.csv
  ##############################################################################
  # compute _i values for _dt values (to support BL date range searching)
  ##############################################################################
  time python3 computeTimeIntegersOMCA.py d9.csv 4solr.${TENANT}.${CORE}.csv
  # clean up some outstanding sins perpetuated by earlier scripts
  perl -i -pe 's/\r//g;s/\\/\//g;s/\t"/\t/g;s/"\t/\t/g;s/\"\"/"/g' 4solr.${TENANT}.${CORE}.csv
  ##############################################################################
  # ok, now let's load this into solr...
  # clear out the existing data
  ##############################################################################
  curl -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
  curl -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
  ##############################################################################
  # this POSTs the csv to the Solr / update endpoint
  # note, among other things, the overriding of the encapsulator with \
  ##############################################################################
  ss_string=`cat uploadparms.${CORE}.txt`
  time curl -X POST -S -s "http://localhost:8983/solr/${TENANT}-${CORE}/update/csv?commit=true&header=true&separator=%09&${ss_string}f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" -T 4solr.${TENANT}.${CORE}.csv -H 'Content-type:text/plain; charset=utf-8' &
  time python3 evaluate.py 4solr.${TENANT}.${CORE}.csv temp.${CORE}.csv > 4solr.fields.${TENANT}.${CORE}.counts.csv &
done
# wait for POSTs to Solr to finish
wait
##############################################################################
# wrap things up: make a gzipped version of what was loaded
##############################################################################
# get rid of intermediate files
rm -f temp*.csv temp.sql t?.*.csv d?.csv m?.csv part*.csv schema*.xml header4Solr.csv public.csv internal.csv
# zip up .csvs, save a bit of space on backups
gzip -f 4solr.*.csv
date
