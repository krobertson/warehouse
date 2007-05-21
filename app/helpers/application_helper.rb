# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def path?(path)
    controller_path[0..path.length-1] == path
  end
  
  def word_for_change(change)
    case change.downcase
      when 'a' then return 'Added'
      when 'd' then return 'Deleted'
      when 'm' then return 'Modified'
      when 'mv' then return 'Moved'
      when 'cp' then return 'Copied'
      else return change
    end
  end
  
  def highlight_as(filename)
    case filename.split('.').last.downcase
      when 'js', 'as' then return 'javascript'
      when 'rb', 'rakefile' then return 'ruby'
      when 'rhtml', 'erb', 'html', 'xml' then return 'html'
      else 'plain'
    end
  end
  
  def title(ttl)
    @title = ttl || ' '
  end
end
