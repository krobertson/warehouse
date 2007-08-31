class HooksController < ApplicationController
  before_filter :repository_admin_required
  
  def index
    @hook  = Hook.new
    @hooks = current_repository.hooks
  end
  
  def create
    @hook = current_repository.hooks.create(params[:hook])
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @hook = current_repository.hooks.find(params[:id])
    @hook.options = params[:hook].to_hash
    respond_to do |format|
      format.js
    end
  end
  
  def destroy
    @hook = current_repository.hooks.find(params[:id])
    @hook.destroy
    respond_to do |format|
      format.js
    end
  end
end
