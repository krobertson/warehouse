# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def path?(path)
    controller_path[0..path.length-1] == path
  end
  
  def word_for_change(change)
    case change.downcase
      when 'a'  then  'Added'
      when 'd'  then  'Deleted'
      when 'm'  then  'Modified'
      when 'mv' then  'Moved'
      when 'cp' then  'Copied'
      else return change
    end
  end
  
  def highlight_as(filename)
    case filename.split('.').last.downcase
      when 'js', 'as' then 'javascript'
      when 'rb', 'rakefile' then 'ruby'
      when 'rhtml', 'erb', 'html', 'xml' then 'html'
      else 'plain'
    end
  end
  
  def modified?(flag)
    flag.downcase == 'm'
  end
  
  def title(ttl)
    @title = ttl || ' '
  end
end
