require_dependency File.expand_path('../lib/basix/tracker_patch', __FILE__)
require_dependency File.expand_path('../lib/basix/basix_hook_listener', __FILE__)

unless Tracker.included_modules.include? Basix::TrackerPatch
    Tracker.send(:include, Basix::TrackerPatch)
end

Redmine::Plugin.register :redmine_basix do
  name 'Basix plugin'
  author 'Brastel Co. Ltd.'
  description 'Redmine Plugin for Integration with Basix'
  version '1.1.0'
  url 'https://github.com/brastelcloud/redmine_basix'
  author_url 'http://www.basix.jp'

  settings default: {'api_uri' => '', 'api_domain' => '', 'api_token' => ''},
           partial: 'settings/basix_settings'
end
