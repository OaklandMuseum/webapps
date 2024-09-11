### Solr ETL ("Extract/Transform/Load") for OMCA
The code in this directory extracts data from OMCA CSpace into csv files and loads them into Solr.

To run this ETL to 'refresh' the omca solr datasources, do something like the following in this directory:

`$ ./solrETL-public.sh omca`

or, via crontab, something like the following (assumes the job is running under user apache):

``
$ crontab -l
0 2 * * * .../omca/solrETL-public.sh omca >> .../omca/solrExtract.log  2>&1
``

NB: This process current runs nightly to refresh the 2 OMCA Solr cores.

The script does the following:

* Extracts via sql the metadata needed for each object
* It does this incrementally via a set of sql query which are stitched together by `join.py`
* The various parts are merged into a single metadata file containing multi-valued fields, latlongs, etc.
* Extracts via sql the media (`blob`) metadata needed for each object
* Merges the two (i.e. adds the blob CSIDs as a multivalued field to the metadata file)
* Clears out the `omca-public` and `omca-internal` solr cores
* Loads the merged .csv files into each solr core.

The script currently takes a little over an  hour to run.

Caveats:

- the query, its results, and the resulting solr datasource are largely unverified. Caveat utilizator!
- the database credentials (dbname, host, user, etc.) are hardcoded in the script. However, it assumes that the password for the database user (normally the CSpace 'reader' user) is in `.pgpass`; add it to the database connect string in
  the script if it isn't.

(jbl 06/15/2014; 05/10/2015; 09/07/2024)
