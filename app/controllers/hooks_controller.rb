class HooksController < ApplicationController
  before_filter :repository_admin_required
  before_filter :find_or_initialize_hook
  
  def index
    @hooks = current_repository.hooks
  end
  
  def create
    @hook.repository = current_repository
    @hook.save
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @hook.options = params[:hook].to_hash
    respond_to do |format|
      format.js
    end
  end
  
  def destroy
    @hook.update_attribute :active, false
    respond_to do |format|
      format.js
    end
  end
  
  def activate
    @hook.update_attribute :active, true
  end
  
  protected
    def find_or_initialize_hook
      @hook = params[:id] ? current_repository.hooks.find(params[:id]) : Hook.new(params[:hook])
    end
end
