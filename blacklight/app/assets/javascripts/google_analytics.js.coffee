
document.addEventListener 'turbolinks:load', (event) ->
  if typeof gtag is 'function'
    // with ga4, it is not necessary to call gtag
    // gtag('event', 'page_view');
