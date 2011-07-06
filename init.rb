require 'redmine'

Dispatcher.to_prepare do
  require_dependency "ovpermits_custom_fields_helper_patch"
  require_dependency "ovpermits_role_patch"
  require_dependency "ovpermits_tracker_patch"
  require_dependency "ovpermits_issue_status_patch"
end

Redmine::Plugin.register :redmine_onevision_permit do
  name 'Redmine Onevision Permission plugin'
  author 'Stefan Langenmainer'
  description 'This is a plugin for Redmine that handles permissions for the issue fields'
  version '0.0.1'
  url 'http://www.onevision.com/'
  author_url 'http://www.onevision.com/about/StefanLangenmaier'
  
  menu :admin_menu, :permits, { :controller => 'permits', :action => 'index' }, :caption => 'Permissions'
end
