require 'open3'
require 'warehouse'
if RAILS_ENV == 'development'
  ENV["RAILS_ASSET_ID"] = ''
end