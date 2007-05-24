class HistoryController < ApplicationController
  before_filter :find_node
  before_filter :repository_member_required

  def index
    
    @changesets = current_repository.changesets.paginate_by_path(@node.path, :page => params[:page])
  end
  
  protected
    def find_node
      @node = current_repository.node(params[:paths] * '/')
    end
end
