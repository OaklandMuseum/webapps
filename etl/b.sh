TENANT=omca
core=internal
curl -S -s http://localhost:8983/solr/omca-internal/update --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s http://localhost:8983/solr/omca-internal/update --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl -S -s "http://localhost:8983/solr/${TENANT}-${core}/update/csv?commit=true&header=true&separator=%09&f.assocculturalcontext_ss.split=true&f.assocculturalcontext_ss.separator=%7C&f.assocorganization_ss.split=true&f.assocorganization_ss.separator=%7C&f.assocperson_ss.split=true&f.assocperson_ss.separator=%7C&f.assocplace_ss.split=true&f.assocplace_ss.separator=%7C&f.material_ss.split=true&f.material_ss.separator=%7C&f.measuredpart_ss.split=true&f.measuredpart_ss.separator=%7C&f.objectproductionorganization_ss.split=true&f.objectproductionorganization_ss.separator=%7C&f.objectproductionperson_ss.split=true&f.objectproductionperson_ss.separator=%7C&f.objectproductionplace_ss.split=true&f.objectproductionplace_ss.separator=%7C&f.title_ss.split=true&f.title_ss.separator=%7C&f.loanstatus_ss.split=true&f.loanstatus_ss.separator=%7C&f.lender_ss.split=true&f.lender_ss.separator=%7C&f.comments_ss.split=true&f.comments_ss.separator=%7C&f.styles_ss.split=true&f.styles_ss.separator=%7C&f.colors_ss.split=true&f.colors_ss.separator=%7C&f.contentconcepts_ss.split=true&f.contentconcepts_ss.separator=%7C&f.contentplaces_ss.split=true&f.contentplaces_ss.separator=%7C&f.contentpersons_ss.split=true&f.contentpersons_ss.separator=%7C&f.contentorganizations_ss.split=true&f.contentorganizations_ss.separator=%7C&f.exhibitionhistories_ss.split=true&f.exhibitionhistories_ss.separator=%7C&f.loanoutnumber_ss.split=true&f.loanoutnumber_ss.separator=%7C&f.borrower_ss.split=true&f.borrower_ss.separator=%7C&f.loaninnumber_ss.split=true&f.loaninnumber_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" --data-binary @4solr.$TENANT.${core}.csv -H 'Content-type:text/plain; charset=utf-8'
core=public
curl -S -s http://localhost:8983/solr/omca-public/update --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s http://localhost:8983/solr/omca-public/update --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'
time curl -S -s "http://localhost:8983/solr/${TENANT}-${core}/update/csv?commit=true&header=true&separator=%09&f.assocculturalcontext_ss.split=true&f.assocculturalcontext_ss.separator=%7C&f.assocorganization_ss.split=true&f.assocorganization_ss.separator=%7C&f.assocperson_ss.split=true&f.assocperson_ss.separator=%7C&f.assocplace_ss.split=true&f.assocplace_ss.separator=%7C&f.material_ss.split=true&f.material_ss.separator=%7C&f.measuredpart_ss.split=true&f.measuredpart_ss.separator=%7C&f.objectproductionorganization_ss.split=true&f.objectproductionorganization_ss.separator=%7C&f.objectproductionperson_ss.split=true&f.objectproductionperson_ss.separator=%7C&f.objectproductionplace_ss.split=true&f.objectproductionplace_ss.separator=%7C&f.title_ss.split=true&f.title_ss.separator=%7C&f.loanstatus_ss.split=true&f.loanstatus_ss.separator=%7C&f.lender_ss.split=true&f.lender_ss.separator=%7C&f.comments_ss.split=true&f.comments_ss.separator=%7C&f.styles_ss.split=true&f.styles_ss.separator=%7C&f.colors_ss.split=true&f.colors_ss.separator=%7C&f.contentconcepts_ss.split=true&f.contentconcepts_ss.separator=%7C&f.contentplaces_ss.split=true&f.contentplaces_ss.separator=%7C&f.contentpersons_ss.split=true&f.contentpersons_ss.separator=%7C&f.contentorganizations_ss.split=true&f.contentorganizations_ss.separator=%7C&f.exhibitionhistories_ss.split=true&f.exhibitionhistories_ss.separator=%7C&f.loanoutnumber_ss.split=true&f.loanoutnumber_ss.separator=%7C&f.borrower_ss.split=true&f.borrower_ss.separator=%7C&f.loaninnumber_ss.split=true&f.loaninnumber_ss.separator=%7C&f.blob_ss.split=true&f.blob_ss.separator=,&encapsulator=\\" --data-binary @4solr.$TENANT.${core}.csv -H 'Content-type:text/plain; charset=utf-8'