require File.dirname(__FILE__) + '/../test_helper'
require 'permissions_controller'

# Re-raise errors caught by the controller.
class PermissionsController
  def rescue_action(e) raise e end
  def check_for_valid_domain() end
end


context "Permissions Controller" do
  setup do
    @controller = PermissionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.stubs(:current_user).returns(users(:rick))
    @request.host = "sample.test.host"
  end

  specify "should grant access to admin" do
    login_as :rick
    get :index
    assert_template 'index'
  end

  specify "should grant access to repository admin" do
    User.any_instance.stubs(:admin?).returns(false)
    login_as :rick
    get :index
    assert_template 'index'
  end

  specify "should not grant access to repository member" do
    login_as :justin
    get :index
    assert_template 'shared/error'
  end

  specify "should grant new permission to repo" do
    assert_difference "Permission.count" do
      assert_no_difference "User.count" do
        post :create, :permission => {:user_id => 2, :path => 'blah'}
        assert_template 'index'
      end
    end
    
    assigns(:permission).user.should.not.be.new_record
    p = repositories(:sample).permissions.find_by_user_id(assigns(:permission).user.id)
    p.should.be.active
    p.should.not.be.admin
  end

  specify "should grant existing member mulitple paths" do
    assert_difference "Permission.count", 2 do
      assert_no_difference "User.count" do
        post :create, :permission => { :user_id => 2, :admin => true, :paths => {'0' => {:path => 'foo'}, '1' => {:path => 'bar', :full_access => true}} }
        assert_template 'index'
      end
    end
    
    assigns(:permission).user.should.not.be.new_record
    perms = repositories(:sample).permissions.find_all_by_user_id(assigns(:permission).user.id).sort_by(&:path)
    perms[0].should.be.active
    perms[0].should.not.be.admin
    perms[0].path.should == '/'
    perms[0].should.not.be.full_access
    perms[1].should.be.active
    perms[1].should.be.admin
    perms[1].path.should == '/bar'
    perms[1].should.be.full_access
    perms[2].should.be.active
    perms[2].should.be.admin
    perms[2].path.should == '/foo'
    perms[2].should.not.be.full_access
  end

  specify "should update user permission" do
    permissions(:rick_sample).should.be.admin
    permissions(:rick_sample).path.should == '/'
    permissions(:rick_sample).clean_path.should == ''

    put :update, :user_id => 1, :permission => { :admin => false, :paths => {'0' => {:path => 'foo', :id => 1}} }
    assert_redirected_to permissions_path
    
    permissions(:rick_sample).reload.should.not.be.admin
    permissions(:rick_sample).path.should == '/foo'
    permissions(:rick_sample).clean_path.should == 'foo'
  end
  
  specify "should update anon permission" do
    permissions(:anon_sample).reload.should.not.be.admin
    permissions(:anon_sample).reload.should.not.be.full_access
    
    put :anon, :permission => { :admin => true, :paths => {'0' => {:id => 2, :full_access => true}} }
    assert_redirected_to permissions_path
    
    permissions(:anon_sample).reload.should.be.admin
    permissions(:anon_sample).reload.should.be.full_access
  end
  
  specify "should delete user permissions" do
    delete :destroy, :user_id => users(:rick).id
    permissions(:rick_sample).active.should == false
  end
  
  specify "should delete anon permissions" do
    delete :anon
    permissions(:anon_sample).active.should == false
  end
  
  specify "should delete permission" do
    delete :destroy, :id => permissions(:rick_sample).id
    permissions(:rick_sample).reload.active.should == false
  end
end

context "Permissions Controller on root domain" do
  setup do
    @controller = PermissionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.stubs(:current_user).returns(users(:rick))
    @request.host = "test.host"
  end

  specify "should show administered repo list to admins" do
    login_as :rick
    get :index
    assert_template 'shared/administered'
  end

  specify "should show administered repo list to repository admins" do
    User.any_instance.stubs(:admin?).returns(false)
    login_as :rick
    get :index
    assert_template 'shared/administered'
  end

  specify "should show administered repo list to repository members" do
    login_as :justin
    get :index
    assert_template 'shared/administered'
  end
end