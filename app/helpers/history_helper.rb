module HistoryHelper
  def link_to_history(text, node, options = {})
    link_to text, history_path(:paths => node.paths), options
  end
end
