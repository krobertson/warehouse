require File.dirname(__FILE__) + '/../test_helper'
require 'permissions_controller'

# Re-raise errors caught by the controller.
class PermissionsController
  def rescue_action(e) raise e end
  def check_for_valid_domain() end
end


context "Permissions Controller" do
  def setup
    @controller = PermissionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.stubs(:current_user).returns(users(:rick))
    @request.host = "sample.test.host"
  end

  specify "should ask for basic authentication on text requests" do
    @controller.stubs(:current_repository).returns(repositories(:sample))
    @controller.stubs(:current_user).returns(nil)
    get :index, :format => 'text'
    assert_response 401
  end

  specify "should login with basic authentication on text requests" do
    @controller.stubs(:current_repository).returns(repositories(:sample))
    @controller.stubs(:current_user).returns(nil)
    @controller.expects(:authenticate_or_request_with_http_basic).yields(users(:rick).token, 'x').returns(users(:rick))
    get :index, :format => 'text'
    assert_response :success
  end

  specify "should grant new permission to repo" do
    assert_difference "Permission.count" do
      assert_no_difference "User.count" do
        post :create, :permission => {:user_id => 2}
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
    perms[0].should.be.admin
    perms[0].path.should == 'bar'
    perms[0].should.be.full_access
    perms[1].should.be.active
    perms[1].should.be.admin
    perms[1].path.should == 'foo'
    perms[1].should.not.be.full_access
  end

  specify "should update user permission" do
    permissions(:rick_sample).should.be.admin
    permissions(:rick_sample).path.should == ''

    put :update, :user_id => 1, :permission => { :admin => false, :paths => {'0' => {:path => 'foo', :id => 1}} }
    assert_redirected_to permissions_path
    
    permissions(:rick_sample).reload.should.not.be.admin
    permissions(:rick_sample).path.should == 'foo'
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
