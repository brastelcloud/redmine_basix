unless Issue.included_modules.include? Basix::TrackerPatch
  Tracker.send(:include, Basix::TrackerPatch)
end

Redmine::Plugin.register :basix do
  name 'Basix plugin'
  author 'Brastel Co. Ltd.'
  description 'Redmine Plugin for Integration with Basix'
  version '1.0.0'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end
