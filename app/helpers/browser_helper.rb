module BrowserHelper
  def url_for_node(node)
    @revision ? rev_browser_path(:paths => node.paths, :rev => params[:rev]) : browser_path(:paths => node.paths)
  end
end
