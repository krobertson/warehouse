require File.dirname(__FILE__) + '/../test_helper'
require 'dashboard_controller'

# Re-raise errors caught by the controller.
class DashboardController; def rescue_action(e) raise e end; end

context "Dashboard Controller" do
  setup do
    @old        = Warehouse.domain
    @controller = DashboardController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  teardown do
    Warehouse.domain = @old
  end

  specify "should get correct domain values for simple root domain" do
    Warehouse.domain = @request.host = 'test.host'
    get :index
    @controller.send(:repository_subdomain).should.be.blank
  end

  specify "should get correct domain values for simple subdomain" do
    Warehouse.domain = 'test.host'
    @request.host = 'foo.test.host'
    get :index
    @controller.send(:repository_subdomain).should == 'foo'
  end

  specify "should get correct domain values for complex root domain" do
    Warehouse.domain = @request.host = 'foo.test.host'
    get :index
    @controller.send(:repository_subdomain).should.be.blank
  end

  specify "should get correct domain values for complex subdomain" do
    Warehouse.domain = 'foo.test.host'
    @request.host = 'bar.foo.test.host'
    get :index
    @controller.send(:repository_subdomain).should == 'bar'
  end

  specify "should get check valid domain for simple root domain" do
    Warehouse.domain = @request.host = 'test.host'
    get :index
    @controller.send(:check_for_valid_domain).should == true
  end

  specify "should get check valid domain for simple subdomain" do
    Warehouse.domain = 'test.host'
    @request.host = 'foo.test.host'
    get :index
    @controller.send(:check_for_valid_domain).should == true
  end

  specify "should get check valid domain for complex root domain" do
    Warehouse.domain = @request.host = 'foo.test.host'
    get :index
    @controller.send(:check_for_valid_domain).should == true
  end

  specify "should get check valid domain for complex subdomain" do
    Warehouse.domain = 'foo.test.host'
    @request.host = 'bar.foo.test.host'
    get :index
    @controller.send(:check_for_valid_domain).should == true
  end

  specify "should get check valid domain for invalid domain" do
    Warehouse.domain = 'foo.test.host'
    @request.host = 'test.host'
    get :index
    assert_template 'layouts/domain'
  end
end
