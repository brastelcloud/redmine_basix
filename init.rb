
if Rails.version > '6.0' && Rails.autoloaders.zeitwerk_enabled?
  unless Tracker.included_modules.include? Basix::TrackerPatch
    Tracker.send(:include, Basix::TrackerPatch)
  end
else
  require_dependency 'basix/hooks'

  unless Tracker.included_modules.include? Basix::TrackerPatch
    Tracker.send(:include, Basix::TrackerPatch)
  end
end

Redmine::Plugin.register :redmine_basix do
  name 'Basix plugin'
  author 'Brastel Co. Ltd.'
  description 'Redmine Plugin for Integration with Basix'
  version '1.0.0'
  url 'https://github.com/brastelcloud/redmine_basix'
  author_url 'http://www.basix.jp'
end
