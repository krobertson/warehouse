class MembersController < ApplicationController
  def index
    @membership = Membership.new
  end
  
  def create
    result = 
      if params[:email].blank?
        current_repository.grant(options)
      else
        @user = User.find_or_initialize_by_email(params[:email])
        current_repository.invite(@user, params[:membership])
      end
    unless result
      render :action => 'new'
      return
    end
    flash[:notice] = "The member at #{params[:email]} was invited successfully."
    redirect_to members_path
  end
end
