require 'open3'
require 'warehouse'
if RAILS_ENV == 'development'
  ENV["RAILS_ASSET_ID"] = ''
end
ActionContentFilter.preserved_instance_variables = %w(@title @onready @fullscreen @current_sheets @content_for_scripts @content_for_onready @content_for_javascript @content_for_sidebar)