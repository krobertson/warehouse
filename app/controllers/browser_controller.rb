class BrowserController < ApplicationController
  before_filter :find_node
  before_filter :repository_member_required
  helper_method :current_revision, :current_changeset, :previous_changeset, :next_changeset

  def index
    @bookmark   = Bookmark.new(:path => @node.path)
    @changesets = current_repository.changesets.find_all_by_path(@node.path, :limit => 5, :order => 'changesets.revision desc')
    render :action => @node.node_type.downcase
  end
  
  def text(raw = false)
    if @node.dir?
      render :layout => false, :content_type => Mime::TEXT
    else
      render :text => @node.content, :content_type => (!raw && @node.text? ? Mime::TEXT : @node.mime_type)
    end
  end

  def raw
    text(true)
  end

  protected
    def repository_member_required
      repository_member? || status_message(:error, "You must be a member of this repository to visit this page.", "browser/error")
    end

    def find_node
      @revision = params[:rev][1..-1].to_i if params[:rev]
      @node     = current_repository.node(params[:paths] * '/', @revision)
    end
    
    def current_revision
      @revision || current_repository.latest_revision
    end
    
    def current_changeset
      @current_changeset ||= @revision ? current_repository.changesets.find_by_revision(@revision) : current_repository.latest_changeset
    end

    def previous_changeset
      @previous_changeset ||= current_repository.changesets.find_by_path(@node.path, :conditions => ['revision < ?', current_revision], :order => 'changesets.revision desc')
    end
    
    def next_changeset
      @next_changeset ||= current_repository.changesets.find_by_path(@node.path, :conditions => ['revision > ?', current_revision], :order => 'changesets.revision')
    end
end
