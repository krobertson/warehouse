require File.dirname(__FILE__) + '/../test_helper'
require 'changesets_controller'

# Re-raise errors caught by the controller.
class ChangesetsController
  def rescue_action(e) raise e end
  def check_for_valid_domain() end
end


context "Changesets Controller" do
  setup do
    @controller = ChangesetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "sample.test.host"
    Repository.any_instance.stubs(:backend).returns(stub(:youngest_rev => 0))
  end

  specify "should show 0 changesets for anonymous user" do
    Repository.any_instance.stubs(:public?).returns(false)
    get :index
    assigns(:changesets).should.be.nil
    assert_template 'error'
  end

  specify "should show changesets for anonymous user on public repo" do
    Repository.any_instance.stubs(:public?).returns(true)
    expect_paginate
    get :index
    assert_template 'index'
  end
  
  specify "should show changesets for admin user" do
    Repository.any_instance.stubs(:public?).returns(false)
    User.any_instance.stubs(:admin?).returns(true)
    expect_paginate
    login_as :rick
    get :index
    assert_template 'index'
  end
  
  specify "should show all changesets for user with all paths" do
    Repository.any_instance.stubs(:public?).returns(false)
    User.any_instance.stubs(:admin?).returns(false)
    expect_paginate
    login_as :rick
    get :index
    assert_template 'index'
  end

  specify "should show changesets for user" do
    Repository.any_instance.stubs(:public?).returns(false)
    User.any_instance.stubs(:admin?).returns(false)
    @controller.stubs(:changeset_paths).returns %w(foo)
    expect_paginate_by_paths [], %w(foo)
    login_as :rick
    get :index
    assert_template 'index'
  end

  private
    def expect_paginate(value = [])
      changesets = stub
      changesets.expects(:search).returns(value)
      Repository.any_instance.expects(:changesets).returns(changesets)
    end

    def expect_paginate_by_paths(value = [], paths = [], page = nil)
      changesets = stub
      changesets.expects(:search_by_paths).with(nil, paths, :page => page, :order => 'changesets.changed_at desc').returns(value)
      Repository.any_instance.expects(:changesets).returns(changesets)
    end
end

context "Changesets Controller on root domain" do
  setup do
    @controller = ChangesetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "test.host"
    Repository.any_instance.stubs(:backend).returns(stub(:youngest_rev => 0))
  end
  
  specify "should redirect anon users to public changesets" do
    get :index
    assert_redirected_to root_public_changesets_path
  end
  
  specify "should allow anon users to public changesets" do
    get :public
    assert_template 'index'
  end
  
  specify "should allow users to public changesets" do
    login_as :rick
    get :public
    assert_template 'index'
  end
  
  specify "should allow users to changesets" do
    login_as :rick
    get :index
    assert_template 'index'
  end
end
