module ApplicationHelper

  def get_documents(query: '*', limit: 12)
    params = {
      :q => query,
      :search_field => "acquisitionreferencenumber_txt",
      :rows => limit,
      :sort => 'asc'
    }
    builder = Blacklight::SearchService.new(config: blacklight_config, user_params: params)
    response = builder.search_results
    docs = response[0][:response][:docs].collect { |x| x.slice(:id,:title_txt, :objectname_txt, :objectname_txt, :objectproductionperson_txt,:objectproductiondate_txt, :blob_ss)}
    return docs
  end

  def get_random_documents(query: '*', limit: 12)
    params = {
      :q => query,
      :search_field => "objectproductionperson_txt",
      :rows => limit,
      :sort => 'random'
    }
    builder = Blacklight::SearchService.new(config: blacklight_config, user_params: params)
    response = builder.search_results
    docs = response[0][:response][:docs].collect { |x| x.slice(:id,:title_txt, :objectname_txt, :objectname_txt, :objectproductionperson_txt,:objectproductiondate_txt, :blob_ss)}
    return docs
  end

  def generate_image_gallery
    docs = get_random_documents(query: 'blob_ss:[* TO *]')
    return format_image_gallery_results(docs)
  end

  def generate_artist_preview(artist)#,limit=4)
    # artist should already include parsed artist names
    # this should return format_artist_preview()
    searchable = extract_artist_names(artist)
    'artist' + artist
    searchable = searchable.split(" AND ")
    random_string = SecureRandom.uuid
    query = ""
    searchable.each do |x|
      query = query + "#{x}"
    end

    docs = get_random_documents(query: query, limit: 4)
    if docs.length > 1
      formatted_documents = docs.collect do |doc|
        content_tag(:a, href: "/catalog/#{doc[:id]}") do
          content_tag(:div, class: 'show-preview-item') do
            if not doc[:title_txt].nil?
              title = doc[:title_txt][0]
            elsif not doc[:objectname_txt].nil?
              title = doc[:objectname_txt][0]
            else
              title = "[No title given]"
            end
            unless doc[:objectproductionperson_txt].nil?
              doc_artist = doc[:objectproductionperson_txt].join('; ')
            else
              doc_artist = "[No maker given]"
            end
            unless doc[:objectproductiondate_txt].nil?
              date_made = '(' + doc[:objectproductiondate_txt][0] + ')'
            else
              date_made = "[No date given]"
            end
            unless doc[:blob_ss].nil?
              image_tag = content_tag(:img, '',
                src: render_csid(doc[:blob_ss][0], 'Medium'),
                class: 'thumbclass')
            else
              image_tag = content_tag(:span,'Image not available',class: 'no-preview-image')
            end
            image_tag +
            content_tag(:h4) do
              content_tag(:span, doc_artist, class: "gallery-caption-artist") +
              content_tag(:span, title, class: "gallery-caption-title") +
              content_tag(:span, date_made, class: "gallery-caption-date")
            end
          end
        end
      end.join.html_safe

      formatted_documents = content_tag(:div, formatted_documents, class: 'show-preview')
      heading = content_tag(:div, class: 'show-preview-heading') do
        content_tag(:p, "More Works by #{artist}")
      end
      return heading + formatted_documents
    end
  end

  def extract_artist_names(artist)
    searchable = artist.tr(",","").gsub("&#39;","'") # first remove commas, translate single quotes
    # we don't need to wrap quotes anymore
    # matches.map!{|m| m.tr(" ","+").insert(0,'"').insert(-1,'"')} # add quotes for the AND search
    matches = searchable.scan(/[^;]+(?=;?)/) # find the names in between optional semi-colons
    if matches.length != 0
      matches = matches.each{|m| m.lstrip!}
      searchable = matches
    end
    return searchable
  end

  def make_artist_search_link(artist)
    return "/catalog/?&op=AND&search_field=objectproductionperson_txt&q=#{artist}"
  end

  def make_artist_search_links(artist)
    searchable = extract_artist_names(artist)
    x = []
    searchable.each do |s|
        x.push(content_tag(:a, s, href: make_artist_search_link(s)))
        # content_tag(:a, s, href: make_artist_search_link(s))
    end
    x.join(', ').html_safe
  end

  def render_csid csid, derivative
    "https://d6jfg2a0yiapu.cloudfront.net/thumbnails/#{csid}.jpg"
    # "/blobs/#{csid}/derivatives/#{derivative}/content"
  end

  def render_status options = {}
    options[:value].collect do |status|
      content_tag(:span, status, style: 'color: red;')
    end.join(', ').html_safe
  end

  def render_multiline options = {}
    # render an array of values as a list
    content_tag(:div) do
      content_tag(:ul) do
        options[:value].collect do |array_element|
          content_tag(:li, array_element)
        end.join.html_safe
      end
    end
  end

  def render_doc_link options = {}
    # return a link to a search for documents for a film
    content_tag(:div) do
      options[:value].collect do |film_id|
        content_tag(:a, 'Click for documents related to this film',
          href: "/?q=#{film_id}&search_field=film_id_ss",
          style: 'padding: 3px;',
          class: 'hrefclass')
      end.join.html_safe
    end
  end

  def render_pdf pdf_csid, restricted
    # render a pdf using html5 pdf viewer
    render partial: '/shared/pdfs', locals: { csid: pdf_csid, restricted: restricted }
  end

  def render_linkless_media options = {}
    # return a list of cards or images
    content_tag(:div) do
      options[:value].collect do |blob_csid|
        content_tag(:a, content_tag(:img, '',
            src: render_csid(blob_csid, 'Medium'),
            class: 'thumbclass'),
          style: 'padding: 3px;')
      end.join.html_safe
    end
  end

  # compute ark from museum number and render as a link
  def render_ark options = {}
    # encode museum number as ARK ID, e.g. 11-4461.1 -> hm21114461@2E1, K-3711a-f -> hm210K3711a@2Df
    options[:value].collect do |musno|
      ark = 'hm2' + if musno.include? '-'
        left, right = musno.split('-', 2)
        left = '1' + left.rjust(2, '0')
        right = right.rjust(7, '0')
        CGI.escape(left + right).gsub('%', '@').gsub('.', '@2E').gsub('-', '@2D').downcase
      else
        'x' + CGI.escape(musno).gsub('%', '@').gsub('.', '@2E').downcase
      end
      link_to "ark:/21549/" + ark, "https://n2t.net/ark:/21549/" + ark
    end.join.html_safe
  end

end
