module BrowserHelper
  def url_for_node(node)
    paths = node.respond_to?(:paths) ? node.paths : node.to_s.split('/')
    @revision ? rev_browser_path(:paths => paths, :rev => params[:rev]) : browser_path(:paths => paths)
  end
end
