require File.dirname(__FILE__) + '/../test_helper'
require 'sessions_controller'

# Re-raise errors caught by the controller.
class SessionsController
  def rescue_action(e) raise e end
  def check_for_valid_domain() end
end


context "Sessions Controller" do
  setup do
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  specify "should not try resetting forgotten account without valid email" do
    get :forget
    assert_match /No user/, @response.body
  end
  
  specify "should set token for forgotten account" do
    post :forget, :email => users(:rick).email
    assert_match /Email sent/, @response.body
  end
  
  specify "should require valid token for reset" do
    get :reset
    assert_match /Invalid token/, @response.body
  end
  
  specify "should not reset identity_url for user on invalid open id login" do
    @controller.expects(:using_open_id?).returns(true)
    @controller.expects(:authenticate_with_open_id).yields(stub(:successful? => false, :message => 'fubar'), nil)
    login_as :rick
    post :reset
    assert_template 'error'
  end
  
  specify "should reset identity_url for user" do
    login_as :rick
    @controller.expects(:using_open_id?).returns(true)
    @controller.expects(:authenticate_with_open_id).yields(stub(:successful? => true), 42)
    @controller.current_user.expects(:identity_url=).with(42).returns(42)
    post :reset
    assert_redirected_to root_path
  end
  
  specify "should show error for invalid open id login attempt" do
    @controller.expects(:using_open_id?).returns(true)
    @controller.expects(:authenticate_with_open_id).yields(stub(:successful? => false, :message => 'fubar'), nil)
    post :create
    assert_template 'error'
  end
  
  specify "should show error for invalid login attempt" do
    @controller.expects(:using_open_id?).returns(false)
    User.expects(:authenticate).with('rick', 'monkey').returns(nil)
    post :create, :login => 'rick', :password => 'monkey'
    assert_template 'error'
  end
  
  specify "should create user from new identity url" do
    @controller.expects(:using_open_id?).returns(true)
    @controller.expects(:authenticate_with_open_id).yields(stub(:successful? => true), 'foobar')
    assert_difference "User.count" do
      post :create
      assert_redirected_to root_path
    end
  end
  
  specify "should login user from with svn password" do
    @controller.expects(:using_open_id?).returns(false)
    User.expects(:authenticate).with('rick', 'monkey').returns(users(:rick))
    assert_no_difference "User.count" do
      post :create, :login => 'rick', :password => 'monkey'
      assert_redirected_to root_path
    end
  end
  
  specify "should login user from existing identity url" do
    @controller.expects(:using_open_id?).returns(true)
    @controller.expects(:authenticate_with_open_id).yields(stub(:successful? => true), users(:rick).identity_url)
    assert_no_difference "User.count" do
      post :create
      assert_redirected_to root_path
    end
  end
end
