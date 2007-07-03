# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def hosted_url(*args)
    options    = args.last.is_a?(Hash) ? args.pop : {}
    name       = args.pop
    repository = args.pop
    options[:host] = repository ? repository.domain : Warehouse.domain
    options[:port] = request.port unless request.port == 80
    send("#{name}_url", options)
  end
  
  def path?(path)
    controller_path[0..path.length-1] == path
  end
  
  def use_login_form?
    @use_login_form ||= !cookies['use_svn'].blank? && cookies['use_svn'].value.to_s == '1'
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
      when 'js', 'as'               then 'javascript'
      when 'rb', 'rakefile', 'rake' then 'ruby'
      when 'css'                    then 'css'
      when 'rhtml', 'erb', 'html', 'xml', 'rxml', 'plist' then 'html'
      else 'plain'
    end
  end
  
  def modified?(flag)
    flag.downcase == 'm'
  end
  
  def title(ttl)
    @title = ttl || ' '
  end
  
  def submit_image(img, options = {})
    tag('input', { :type => 'image', :class => 'submit', :src => "/images/app/btns/#{img}" }.merge(options))
  end
  
  def cancel_image(options = {})
    image_tag('/images/app/btns/cancel.png', {:class => 'imgbtn cancelbtn'}.merge(options))
  end
  
  def class_for(options)
    %(class="selected") if current_page?(options)
  end
  
  def avatar_for(user)
    img = user && user.avatar? ? user.avatar_path : '/images/app/icons/member.png'
    tag('img', :src => img, :class => 'avatar')
  end

  def distance_of_time_in_words(from_time, to_time = 0, format = :short)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time   = to_time.to_time   if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round

    case distance_in_minutes
      when 0..1            then (distance_in_minutes == 0) ? 'less than a minute ago' : '1 minute ago'
      when 2..44           then "#{distance_in_minutes} minutes ago"
      when 45..89          then 'about 1 hour ago'
      when 90..1439        then "about #{(distance_in_minutes.to_f / 60.0).round} hours ago"
      when 1440..2879      then '1 day ago'
      else jstime(from_time, format)
    end
  end

  def jstime(time, format = :short)
    content_tag 'span', time.to_s(format), :class => 'time'
  end

  # UTC FTW
  def time_ago_in_words(from_time, include_seconds = false)
    distance_of_time_in_words(from_time, Time.now.utc, include_seconds)
  end

  # simple wrapper around #cache that checks the current_cache hash 
  # for cached data before reading the fragment.  See #current_cache
  # and #cached_in? in ApplicationController
  def cache_or_show(name, use_cache = true, &block)
    if name.nil? || !use_cache
      block.call
    elsif current_cache[name]
      concat current_cache[name], block.binding
    else
      cache(name, &block)
    end
  end
end
