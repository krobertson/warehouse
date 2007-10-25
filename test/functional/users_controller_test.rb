require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController
  def rescue_action(e) raise e end
  def check_for_valid_domain() end
end

context "Users Controller" do
  setup do
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "sample.test.host"
  end
  
  specify "should allow user to update self" do
    login_as :justin
    put :update, :user => {:email => 'justin2@wh.com'}
    assert_redirected_to root_path
    users(:justin).email.should == 'justin2@wh.com'
  end
  
  specify "should not allow user to update admin setting" do
    login_as :justin
    put :update, :user => {:email => 'justin2@wh.com', :admin => '1'}
    assert_redirected_to root_path
    users(:justin).should.not.be.admin
  end
  
  specify "should allow admin to update user admin setting" do
    login_as :rick
    put :update, :id => 2, :user => {:email => 'justin2@wh.com', :admin => '1'}
    assert_redirected_to root_path
    users(:justin).should.be.admin
  end
  
  specify "should not allow user for update with id" do
    login_as :justin
    put :update, :id => 1
    assert_select '#error'
  end
end

context "Users Controller Access" do
  setup do
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "sample.test.host"
    class << @controller
      def status_message(type, message = nil)
        render :text => "#{type}: #{message.inspect}"
        false
      end

      def login_required_with_testing
        login_required_without_testing
        render :text => 'passed' unless performed?
        false
      end
      alias_method_chain :login_required, :testing

      def admin_required_with_testing
        admin_required_without_testing
        render :text => 'passed' unless performed?
        false
      end
      alias_method_chain :admin_required, :testing
    end
  end

  specify "should allow admin for index" do
    login_as :rick
    get :index
    assert_match /^passed/, @response.body
  end

  specify "should not allow user for index" do
    login_as :justin
    get :index
    assert_match /^error/, @response.body
  end

  specify "should not allow anon for index" do
    get :index
    assert_match /^error/, @response.body
  end

  specify "should allow admin for create" do
    login_as :rick
    post :create
    assert_match /^passed/, @response.body
  end

  specify "should not allow user for create" do
    login_as :justin
    post :create
    assert_match /^error/, @response.body
  end

  specify "should not allow anon for create" do
    post :create
    assert_match /^error/, @response.body
  end

  specify "should allow admin for destroy" do
    login_as :rick
    get :index, :id => 2
    assert_match /^passed/, @response.body
  end

  specify "should not allow user for destroy" do
    login_as :justin
    get :index, :id => 2
    assert_match /^error/, @response.body
  end

  specify "should not allow anon for destroy" do
    get :index, :id => 2
    assert_match /^error/, @response.body
  end
  
  specify "should allow admin for update" do
    login_as :rick
    put :update, :id => 2
    assert_match /^passed/, @response.body
  end

  specify "should allow user for update without id" do
    login_as :justin
    put :update
    assert_match /^passed/, @response.body
  end
end
