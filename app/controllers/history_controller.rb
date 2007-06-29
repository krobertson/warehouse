class HistoryController < ApplicationController
  before_filter :find_node
  before_filter :repository_member_required

  caches_action_content :index

  def index
    @changesets = current_repository.changesets.paginate_by_path(@node.path, :page => params[:page])
    @users      = User.find_all_by_logins(@changesets.collect(&:author).uniq).index_by(&:login)
  end
  
  protected
    def find_node
      @node = current_repository.node(params[:paths] * '/')
      unless @node.accessible_by?(current_user)
        status_message :error, "You do not have access to this path."
        false
      else
        true
      end
    end
end
