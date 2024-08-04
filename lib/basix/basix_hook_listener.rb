module Basix
  class BasixHookListener < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      js = "
$(document).ready(function() {
  try {
    $('a').each(function() {
      var re = /basix\\/(voicemail|callrecording)\\/.*\\.(wav|mp3)/
      try {
        var href = $(this).attr('href')
        if(href && href.match(re)) {
          $(this).replaceWith(\"<audio controls preload='none'><source src=\" + href + '/></audio>')
        }
      } catch(err) {
        console.log(`Failed when processing audio link: ${err}`) 
      }
    })
  } catch (err) {
    console.log(`Failed when processing audio links: ${err}`) 
  }
})
"
      "<script type=\"text/javascript\">#{javascript_cdata_section(js)}</script>"
    end
  end
end
