require 'open3'
if RAILS_ENV == 'development'
  ENV["RAILS_ASSET_ID"] = ''
end