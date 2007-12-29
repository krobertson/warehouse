module HistoryHelper
  def link_to_history(text, node, options = {})
    link_to text, hosted_url(:history, :paths => node.paths), options
  end
end
