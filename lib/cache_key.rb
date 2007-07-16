require 'fileutils'
module CacheKey
  extend self
  
  def bookmarks_for(repository)
    "/repositories/%s/bookmarks" % record_id(repository)
  end
  
  def record_id(object)
    partition_num(object.is_a?(ActiveRecord::Base) ? object.id : object)
  end
  
  # turns a larger num like 12345 to 0001/2345
  def partition_num(num)
    ("%08d" % num.to_i).scan(/..../) * '/'
  end
  
  def sweep_cache(request = nil, repository = nil)
    cache_path = File.join(RAILS_ROOT, 'tmp', 'cache')
    cache_path = File.join(cache_path, repository.domain) if repository
    cache_path << ".#{request.port}" if repository && request && request.port != 80
    FileUtils.rm_rf(cache_path) if File.exist?(cache_path)
  end
end