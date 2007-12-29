module BrowserHelper
  def link_to_node(text, node, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    link_to text, url_for_node(node, args.first), options
  end

  def url_for_node(node, rev = nil)
    paths = node.respond_to?(:paths) ? node.paths : node.to_s.split('/')
    rev = rev ? rev.to_s : params[:rev]
    rev = "r#{rev}" unless rev.nil? || rev =~ /^r/
    rev ? rev_browser_path(:paths => paths, :rev => rev) : browser_path(:paths => paths)
  end
  
  def link_to_blame(text, node)
    link_to text, url_for_blame(node), :id => (Object.const_defined?(:Uv) ? :blame : nil)
  end
  
  def url_for_blame(node)
    paths = node.respond_to?(:paths) ? node.paths : node.to_s.split('/')
    blame_path(:paths => paths)
  end
  
  def link_to_crumbs(path, rev = nil)
    pieces    = path.split '/'
    name      = pieces.pop
    home_link = %(<li#{' class="crumb-divide-last"' if pieces.size == 0 && !name.nil?}>#{link_to '~', (rev ? rev_browser_path : browser_path)}</li>)
    return home_link unless name
    prefix = ''
    crumbs = []
    pieces.each_with_index do |piece, i|
      crumbs << %(<li#{' class="crumb-divide-last"' if pieces.size == i+1}>#{link_to_node(piece, "#{prefix}#{piece}", rev)}</li>)
      prefix << piece << '/'
    end
    crumbs.unshift(home_link).join << %(<li id="current">#{name}</li>)
  end
  
  def css_class_for(node)
    node.dir? ? 'folder' : CSS_CLASSES[File.extname(node.name)] || 'file'
  end
end
