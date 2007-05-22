require File.dirname(__FILE__) + '/../test_helper'
require 'permissions_controller'

# Re-raise errors caught by the controller.
class PermissionsController; def rescue_action(e) raise e end; end

context "Permissions Controller" do
  def setup
    @controller = PermissionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  specify "should grant new permission to repo" do
    assert_difference "Permission.count" do
      post :create, :email => 'imagetic@wh.com', :permission => { :login => 'imagetic' }
      assert_redirected_to permissions_path
    end
    
    assigns(:user).should.not.be.new_record
    m = repositories(:sample).permissions.find_by_user_id(assigns(:user).id)
    m.login.should == 'imagetic'
    m.should.be.active
    m.should.not.be.admin
  end

  specify "should invite new member to repo" do
    assert_difference "Permission.count" do
      post :create, :email => 'justin@wh.com', :permission => { :login => 'justin', :admin => true }
      assert_redirected_to permissions_path
    end
    
    assigns(:user).should.not.be.new_record
    m = repositories(:sample).permissions.find_by_user_id(assigns(:user).id)
    m.login.should == 'justin'
    m.should.be.active
    m.should.be.admin
    u = repositories(:sample).members.find_by_id(assigns(:user).id)
    u.should.be.permission_admin
  end
  
  specify "should not invite new user with invalid email" do
    post :create, :email => 'foobar', :permission => { :login => 'foobar' }
    assert_template 'new'
    assigns(:user).should.be.new_record
  end
end
