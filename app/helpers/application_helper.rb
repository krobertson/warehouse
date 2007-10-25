# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def path?(path)
    controller_path[0..path.length-1] == path
  end
  
  def full_svn_url?
    @full_svn_url || (current_repository && current_repository.full_url)
  end
  
  def full_svn_url
    @full_svn_url ||= current_repository.full_url.dup << (@node ? @node.path : '')
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
  
begin
  require 'rubygems' unless Object.const_defined?(:Gem)
  require 'uv'
  require 'uv_extensions'
  Uv.syntax_list = %w(actionscript c c++ coldfusion css csv diff erlang haml haskell html html-asp html_for_asp.net html_mason html_rails icalendar java javascript json lisp markdown textile plain_text objective-c perl php python ragel ruby sql xml xsl yaml)
  Uv.init_syntaxes
  def highlight_as(filename)
    Uv.syntax_for_file(filename) || 'plain_text'
  end
  
  def highlight_syntax_in(node)
    parsed = nil
    benchmark "Highlighting #{node.path}" do
      parsed = Uv.parse(node.content, "xhtml", highlight_as(node.path.split("/").last), true, :twilight)
      parsed.gsub!(/<span class="line-numbers">(\s+\d+\s+)<\/span>/) do |s|
        %(<span class="line-numbers" id="n-#{$1.to_i}"><a href="#n-#{$1.to_i}">#{$1}</a></span>)
      end
    end
    parsed
  end
rescue LoadError
  def highlight_as(filename)
    case filename.split('.').last.downcase
      when 'js', 'as'               then 'javascript'
      when 'rb', 'rakefile', 'rake' then 'ruby'
      when 'css'                    then 'css'
      when 'rhtml', 'erb', 'html', 'xml', 'rxml', 'plist' then 'html'
      else 'plain'
    end
  end
  
  def highlight_syntax_in(node)
    %(<pre class="viewsource"><code class="#{highlight_as(node.path.split('/').last)}">#{h node.content}</code></pre>)
  end
  
  puts "No Ultraviolet gem found, defaulting to javascript syntax highlighting.  Do not be afraid."
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
  
  @@selected_attribute = %( class="selected").freeze
  def class_for(options)
    @@selected_attribute if current_page?(options)
  end
  
  def selected_navigation?(navigation)
    @@selected_attribute if current_navigation?(navigation)
  end
  
  def current_navigation?(navigation)
    @current_navigation ||= \
      case controller.controller_name
        when /browser|history/ then :browser
        when /change/          then :activity
        else                        :admin
      end
    @current_navigation == navigation
  end
  
  def avatar_for(user)
    img = user && user.avatar? ? user.avatar_path : '/images/app/icons/member.png'
    tag('img', :src => img, :class => 'avatar', :alt => 'avatar')
  end

  @@default_jstime_format = "%d %b, %Y %I:%M %p"
  def jstime(time, format = nil)
    content_tag 'span', time.strftime(format || @@default_jstime_format), :class => 'time'
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
  
  def link_to_tab(name, url = {}, options = {})
    link_to name, url, options
  end
end
