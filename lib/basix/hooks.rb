module Basix
  class BasixHookListener < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      js = "
$(document).ready(function() {
  $('a').each(function() {
    var audio_suffixes = ['wav', 'mp3', 'ogg'];
    var suffix = $(this).attr('href').split('.').pop();
    if(audio_suffixes.indexOf(suffix) >= 0) {
      $(this).replaceWith(\"<audio controls preload='none'><source src=\" + $(this).attr('href') + '/></audio>')
    }
  });
})
"
      "<script type=\"text/javascript\">#{javascript_cdata_section(js)}</script>"
    end
  end
end
