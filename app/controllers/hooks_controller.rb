class HooksController < ApplicationController
  before_filter :repository_admin_required
  before_filter :find_hook, :except => [:index, :create]
  
  def index
    @hooks = current_repository.hooks.group_by { |h| h.name }
  end
  
  def create
    @hook = current_repository.hooks.create!(:name => params[:name], :options => params[:hook])
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @hook.options = params[:hook]
    respond_to do |format|
      format.js
    end
  end
  
  def destroy
    @hook.destroy
    respond_to do |format|
      format.js
    end
  end
  
  protected
    def find_hook
      @hook = current_repository.hooks.find(params[:id])
    end
end
