# frozen_string_literal: true
class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller

  include Blacklight::Catalog
  include BlacklightRangeLimit::ControllerOverride

  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'edismax'
    config.advanced_search[:form_solr_parameters] ||= {}

    config.view.gallery(document_component: Blacklight::Gallery::DocumentComponent)
    config.view.masonry(document_component: Blacklight::Gallery::DocumentComponent)
    # config.view.slideshow(document_component: Blacklight::Gallery::SlideshowComponent)
    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)

    # disable these three document action until we have resources to configure them to work
    config.show.document_actions.delete(:citation)
    config.show.document_actions.delete(:sms)
    config.show.document_actions.delete(:email)

    # config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    # config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    # config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # solr path which will be added to solr base url before the other solr params.
    config.solr_path = 'select'
    config.document_solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [12,24,48,100]

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    #
    # UCB customizations to support existing Solr cores
    config.default_solr_params = {
        'rows': 12,
        'facet.mincount': 1,
        'q.alt': '*:*',
        'defType': 'edismax',
        'df': 'text',
        'q.op': 'AND',
        'q.fl': '*,score'
    }

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
        qt: 'document',
        #  ## These are hard-coded in the blacklight 'document' requestHandler
        #  # fl: '*',
        #  # rows: 1,
        # this is needed for our Solr services
        q: '{!term f=id v=$id}'
    }

    # solr field configuration for search results/index views
    # UCB customization: list of blobs is hardcoded for both index and show displays
    #{index_title}
    config.index.thumbnail_field = 'blob_ss'

    # solr field configuration for document/show views
    #{show_title}
    config.show.thumbnail_field = 'blob_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    # UCB Customizations to use existing "catchall" field called text
    config.add_search_field 'text', label: 'Any field'
    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    #   config.add_search_field('text') do |field|
    #     # solr_parameters hash are sent to Solr as ordinary url query params.
    #     field.solr_parameters = { :'spellciheck.dictionary' => 'text' }
    #
    #     # :solr_local_parameters will be sent using Solr LocalParams
    #     # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    #     # Solr parameter de-referencing like $title_qf.
    #     # See: http://wiki.apache.org/solr/LocalParams
    #     field.solr_local_parameters = {
    #       qf: '$text_qf',
    #       pf: '$text_pf'
    #     }
    #   end
    #
    #    config.add_search_field('author') do |field|
    #      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
    #      field.solr_local_parameters = {
    #        qf: '$author_qf',
    #        pf: '$author_pf'
    #      }
    #    end
    #
    #    # Specifying a :qt only to show it's possible, and so our internal automated
    #    # tests can test it. In this case it's the same as
    #    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    #    config.add_search_field('subject') do |field|
    #      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
    #      field.qt = 'search'
    #      field.solr_local_parameters = {
    #        qf: '$subject_qf',
    #        pf: '$subject_pf'
    #   }
    # end

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = false
    config.autocomplete_path = 'suggest'

    # FACET FIELDS
    config.add_facet_field 'objectname_ss', label: 'Object name', limit: true
    # config.add_facet_field 'collection_s', label: 'Collection', limit: true
    config.add_facet_field 'material_ss', label: 'Material', limit: true
    # config.add_facet_field 'measuredpart_ss', label: 'Measured part', limit: true
    config.add_facet_field 'objectproductionperson_ss', label: 'Maker', limit: true
    config.add_facet_field 'contentconcepts_ss', label: 'Concepts', limit: true
    config.add_facet_field 'contentplaces_ss', label: 'Places', limit: true
    config.add_facet_field 'contentpersons_ss', label: 'Persons', limit: true
    config.add_facet_field 'contentorganizations_ss', label: 'Organizations', limit: true
    # config.add_facet_field 'assocculturalcontext_ss', label: 'Cultural affinity', limit: true
    # config.add_facet_field 'fieldcollectionplace_s', label: 'Field collection place', limit: true
    # config.add_facet_field 'fieldcollectiondate_ss', label: 'Field collection date', limit: true
    # config.add_facet_field 'fieldcollectors_ss', label: 'Field collector(s)', limit: true

    config.add_facet_field("objectproductionscalardate_i") do |field|
      field.include_in_advanced_search = false
      field.label = 'Date made'
      field.range = true
      field.index_range = true
    end
    config.add_facet_field 'has_images_s', label: 'Has image(s)'
    # config.add_facet_field 'Has image', query: {
    #    has_image: { label: 'Yes', fq: 'blob_ss:[* TO *]' },
    #    no_image: { label: 'No', fq: '-(blob_ss:[* TO *])' }
    # }
    # config.add_facet_field 'highlights_ss', label: 'Highlights', limit: true
    config.add_facet_field 'ondisplay_s', label: 'On display', limit: true

    # config.add_facet_field 'accessiondate_s', label: 'Accession date (str)', limit: true
    # config.add_facet_field 'accessiondate_dt', label: 'Accession date (sca)', limit: true
    # config.add_facet_field 'first_s', label: 'Firsts', limit: true


    # SEARCH FIELDS
    [
      ['objectname_txt', 'Object name'],
      ['objectnumber_s', 'Object number'],
      ['collection_txt', 'Collection'],
      ['material_txt', 'Material'],
      # [ 'measuredpart_txt', 'Measured part'],
      ['objectproductionperson_txt', 'Maker'],
      ['contentconcepts_txt', 'Concepts'],
      ['contentplaces_txt', 'Places'],
      ['contentpersons_txt', 'Persons'],
      ['contentorganizations_txt', 'Organizations'],
      ['recent_acquisitions_s', 'Acquisitions']
      ].each do |search_field|
      config.add_search_field(search_field[0]) do |field|
        field.label = search_field[1]
        #field.solr_parameters = { :'spellcheck.dictionary' => search_field[0] }
        field.solr_parameters = {
          qf: search_field[0],
          pf: search_field[0],
          op: 'AND'
        }
      end
    end

    # 'SHOW' VIEW FIELDS
    config.add_show_field 'objectnumber_s', label: 'Object number'
    config.add_show_field 'objectname_ss', label: 'Object name'
    config.add_show_field 'title_ss', label: 'Title'
    config.add_show_field 'dhname_ss', label: 'Scientific name'
    config.add_show_field 'objectproductionperson_ss', label: 'Maker'
    config.add_show_field 'objectproductionorganization_ss', label: 'Production organization'
    config.add_show_field 'objectproductiondate_ss', label: 'Date made'
    config.add_show_field 'argusdescription_s', label: 'Material/Technique'
    # config.add_show_field 'material_ss', label: 'Material'
    config.add_show_field 'dimensionsummary_s', label: 'Dimensions'
    # config.add_show_field 'measuredpart_ss', label: 'Measured part'
    config.add_show_field 'creditline_s', label: 'Credit line'
    config.add_show_field 'ipaudit_s', label: 'Copyright status'
    config.add_show_field 'copyrightholder_s', label: 'Copyright holder'
    config.add_show_field 'physicaldescription_s', label: 'Physical description'
    config.add_show_field 'contentdescription_s', label: 'Content description'
    config.add_show_field 'assocculturalcontext_ss', label: 'Cultural affinity'
    config.add_show_field 'fieldcollectionplace_s', label: 'Field collection place'
    config.add_show_field 'fieldcollectiondate_ss', label: 'Field collection date'
    config.add_show_field 'fieldcollectors_ss', label: 'Field collector(s)'
    config.add_show_field 'fieldcollectionnote_s', label: 'Field collection note'
    config.add_show_field 'contentconcepts_ss', label: 'Concepts'
    config.add_show_field 'contentplaces_ss', label: 'Places'
    config.add_show_field 'contentpersons_ss', label: 'Persons'
    config.add_show_field 'contentorganizations_ss', label: 'Organizations'
    # config.add_show_field 'nagprastatement_s', label: 'NAGPRA statement'
    # config.add_show_field 'ondisplay_s', label: 'Currently on display in the'
    # config.add_show_field 'ondisplaylocation_s', label: 'Museum location'
    # config.add_show_field 'collection_s', label: 'Collection'
    # config.add_show_field 'argusremarks_s', label: 'Argus remarks'
    # config.add_show_field 'briefdescription_s', label: 'Brief description'

    # config.add_show_field 'accessiondate_s', label: 'Accession date (str)'
    # config.add_show_field 'accessiondate_dt', label: 'Accession date (sca)'

    # blobs are now rendered using the 'gallery' approach in the show partials _show_default
    # config.add_show_field 'blob_ss', helper_method: 'render_media', label: 'Images'

    # 'INDEX' VIEW FIELDS
    config.add_index_field 'objectnumber_s', label: 'Object number'
    config.add_index_field 'objectname_ss', label: 'Object name'
    config.add_index_field 'title_ss', label: 'Title'
    config.add_index_field 'dhname_ss', label: 'Scientific name'
    config.add_index_field 'objectproductionperson_ss', label: 'Maker'
    config.add_index_field 'assocculturalcontext_ss', label: 'Cultural affinity'
    config.add_index_field 'objectproductiondate_ss', label: 'Date made'
    # config.add_index_field 'dimensionsummary_s', label: 'Dimensions'
    # config.add_index_field 'material_ss', label: 'Material'
    # config.add_index_field 'briefdescription_s', label: 'Brief description'
    # config.add_index_field 'ondisplay_s', label: 'On display'

    # config.add_index_field 'accessiondate_s', label: 'Accession date (str)'
    # config.add_index_field 'accessiondate_dt', label: 'Accession date (sca)'

    config.index.title_field = 'objectnumber_s'
    # but note objectnumber_s is not displayed in the Show view
    config.show.title_field = 'objectnumber_s'

    # SORT FIELDS
    config.add_sort_field 'has_images_s desc, first_s desc, sortableobjectnumber_s asc', label: 'Image, then Object number'
    config.add_sort_field 'sortableobjectnumber_s asc', label: 'Object number'
    config.add_sort_field 'objectname_ss asc', label: 'Object name A-Z'
    config.add_sort_field 'title_s asc', label: 'Title A-Z'
    config.add_sort_field 'objectproductionscalardate_i asc', label: 'Date made ascending'
    config.add_sort_field 'objectproductionscalerdate_i desc', label: 'Date made descending'
    # config.add_sort_field 'accessiondate_dt desc', label: 'Accession date, descending'
  end
end
