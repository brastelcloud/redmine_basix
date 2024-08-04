
unless Tracker.included_modules.include? Basix::TrackerPatch
    Tracker.send(:include, Basix::TrackerPatch)
end

require File.expand_path('../lib/basix/basix_hook_listener', __FILE__)

Redmine::Plugin.register :redmine_basix do
  name 'Basix plugin'
  author 'Brastel Co. Ltd.'
  description 'Redmine Plugin for Integration with Basix'
  version '1.1.0'
  url 'https://github.com/brastelcloud/redmine_basix'
  author_url 'http://www.basix.jp'
end
