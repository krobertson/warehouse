class HistoryController < ApplicationController
  before_filter :find_node
  before_filter :repository_member_required

  def index
    @changesets = current_repository.changesets.paginate_by_path(@node.path, :page => params[:page])
    @users      = User.find_all_by_logins(current_repository, @changesets.collect(&:author).uniq).index_by(&:login)
  end
  
  protected
    def find_node
      @node = current_repository.node(params[:paths] * '/')
    end
end
