# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def path?(path)
    controller_path[0..path.length-1] == path
  end
  
  def full_svn_url?
    @full_svn_url || (controller.controller_name == 'browser' && current_repository && current_repository.full_url)
  end
  
  def full_svn_url
    @full_svn_url ||= current_repository.full_url.dup << (@node ? @node.path : '')
  end
  
  def use_login_form?
    @use_login_form ||= !(!cookies['use_svn'].blank? && cookies['use_svn'].to_s == '1')
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
  
  def nb_pad(s, num)
    s.to_s.ljust(num).gsub(' ', '&nbsp;')
  end
  
if Object.const_defined?(:Uv)
  def highlight_as(filename)
    Uv.syntax_for_file(filename) || 'plain_text'
  end
  
  def highlight_syntax_in(node, show_blame=false)
    parsed = nil
    benchmark "Highlighting #{node.path}" do
      parsed = Uv.parse(node.content, "xhtml", highlight_as(node.path.split("/").last), true, Warehouse.source_highlight_theme)
      parsed.gsub!(/<span class="line-numbers">(\s+\d+\s+)<\/span>/) do |s|
        line_num = $1.to_i
        line_len = node.blame.size.to_s.length
        rev, username = node.blame[line_num]
        %(<span class="line-numbers" id="n-#{line_num}"><span class="blame" title="#{username} modified this code in ##{rev}">#{link_to("#{nb_pad username, node.blame[:username_length]}", hosted_url(current_repository, :changeset, :id => rev))}&nbsp;</span><a href="#n-#{line_num}">#{nb_pad line_num, line_len}</a></span>)
      end
      parsed.gsub! /^<pre class="/, %(<pre id="source-code" class="#{'noblame ' unless show_blame})
    end
    parsed
  end
else
  def highlight_as(filename)
    case filename.split('.').last.downcase
      when 'js', 'as'               then 'javascript'
      when 'rb', 'rakefile', 'rake' then 'ruby'
      when 'css'                    then 'css'
      when 'rhtml', 'erb', 'html', 'xml', 'rxml', 'plist' then 'html'
      else 'plain'
    end
  end
  
  def highlight_syntax_in(node, show_blame=false)
    %(<pre class="viewsource">
      <code class="#{highlight_as(node.path.split('/').last)}">#{h node.content}</code>
    </pre>)
  end
  
  def blame_for(node)
    lines = node.content.split("\n")
    lines.each_with_index do |line, i|
      rev, username = node.blame[i+1]
      line.replace "#{i+1} #{truncate(rev, 7, '')} #{username.ljust(node.blame[:username_length])} #{line}"
    end
    %(<pre><code>#{h lines.join("\n")}</code></pre>)
  end
end
  
  def modified?(flag)
    flag.downcase == 'm'
  end
  
  def title(ttl)
    @title = ttl.nil? || ttl.blank? ? nil : ttl
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
        when /browser|history/  then :browser
        when /change/           then :activity
        when /dashboard/	  	  then :dashboard
        else                    :admin
      end
    @current_navigation == navigation
  end
  
  def avatar_for(user)
    img = user && user.avatar? ? user.avatar_path : '/images/app/icons/member.png'
    tag('img', :src => img, :class => 'avatar', :alt => 'avatar')
  end
  
  def changeset_feed_url(repo = current_repository)
    if repo
      hosted_url(:formatted_changesets, :atom)
    else
      logged_in? && controller.action_name != 'public' ? formatted_root_changesets_path(:atom) : formatted_root_public_changesets_path(:atom)
    end
  end
  
  def activity_url(repo = current_repository)
    if repo
      hosted_url :changesets
    else
      logged_in? ? root_changesets_path : root_public_changesets_path
    end
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
