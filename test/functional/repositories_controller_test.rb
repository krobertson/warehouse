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

  specify "should not grant access to repository member" do
    login_as :justin
    get :index
    assert_template 'layouts/error'
    assigns(:repositories).should.be.nil
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

  specify "should not grant access to repository admin" do
    User.any_instance.stubs(:admin?).returns(false)
    login_as :rick
    get :index
    assert_redirected_to changesets_path
    assigns(:repositories).should.be.nil
  end

  specify "should not grant access to repository member" do
    login_as :justin
    get :index
    assert_redirected_to changesets_path
    assigns(:repositories).should.be.nil
  end
end