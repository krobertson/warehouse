require File.dirname(__FILE__) + '/../test_helper'
require 'repositories_controller'

# Re-raise errors caught by the controller.
class RepositoriesController
  def rescue_action(e) raise e end
  def check_for_valid_domain() end
end


context "Repositories Controller" do
  setup do
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = 'sample.test.host'
    Repository.any_instance.stubs(:sync_revisions).returns(["50", []])
    Repository.any_instance.stubs(:latest_revision).returns(100)
  end

  specify "should grant access to admin" do
    login_as :rick
    get :sync, :id => 1
    assert_template nil
  end

  specify "should grant access to repository admin" do
    User.any_instance.stubs(:admin?).returns(false)
    login_as :rick
    get :sync, :id => 1
    assert_template nil
  end

  specify "should not grant access to repository member" do
    login_as :justin
    get :sync, :id => 1
    assert_template 'shared/error'
    assigns(:repositories).should.be.nil
  end

  specify "should grant access to #index for admin" do
    login_as :rick
    get :index
    assert_template 'index'
    assigns(:repositories).size.should == 2
  end

  specify "should grant access to #index for repository admin" do
    User.any_instance.stubs(:admin?).returns(false)
    login_as :rick
    get :index
    assert_template 'index'
    assigns(:repositories).size.should == 1
  end

  specify "should grant access to #index for repository member" do
    login_as :justin
    get :index
    assert_template 'index'
    assigns(:repositories).should.be.empty
  end
end

context "Repositories Controller on root domain" do
  setup do
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = 'test.host'
  end

  specify "should grant access to admin" do
    login_as :rick
    get :index
    assert_template 'index'
    assigns(:repositories).size.should == 2
  end

  specify "should grant access to repository admin" do
    User.any_instance.stubs(:admin?).returns(false)
    login_as :rick
    get :index
    assert_template 'index'
    assigns(:repositories).size.should == 1
  end

  specify "should grant access to repository member" do
    login_as :justin
    get :index
    assert_template 'index'
    assigns(:repositories).should.be.empty
  end
end