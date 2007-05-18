class HistoryController < ApplicationController
  def index
    @node       = current_repository.node(params[:paths] * '/')
    @changesets = current_repository.changesets.find_all_by_path(@node.path)
  end
end
