class HistoryController < ApplicationController
  before_filter :find_node
  before_filter :repository_member_required

  caches_action_content :index

  def index
    @changesets = current_repository.changesets.paginate_by_path(@node.path, :page => params[:page])
    if api_format?
      render :layout => false
    else
      @users = User.find_all_by_logins(@changesets.collect(&:author).uniq).index_by(&:login)
    end
  end
  
  protected
    def find_node
      full_path = if params[:paths].last.to_s =~ /\.atom$/
        request.format = :atom
        params[:paths].first(params[:paths].size - 1)
      else
        params[:paths]
      end
      @node = current_repository.node(full_path * "/")
      unless @node.accessible_by?(current_user)
        status_message :error, "You do not have access to this path."
        false
      else
        true
      end
    end
end
