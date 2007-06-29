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
end