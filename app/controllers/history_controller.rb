class HistoryController < ApplicationController
  def index
    @node       = repository.node(params[:paths] * '/')
    @changesets = repository.changesets.find_all_by_path(@node.path, :order => 'revision desc')
  end
end
