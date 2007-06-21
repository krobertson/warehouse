require File.dirname(__FILE__) + '/../test_helper'
require 'changesets_controller'

# Re-raise errors caught by the controller.
class ChangesetsController; def rescue_action(e) raise e end; end

context "Changesets Controller" do
  def setup
    @controller = ChangesetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "sample.test.host"
  end

  specify "should show 0 changesets for anonymous user" do
    Repository.any_instance.stubs(:public?).returns(false)
    get :index
    assigns(:changesets).size.should.be.zero
    assert_template 'index'
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
    User.any_instance.expects(:permissions).returns(stub(:paths_for => :all))
    expect_paginate
    login_as :rick
    get :index
    assert_template 'index'
  end

  specify "should show changesets for user" do
    Repository.any_instance.stubs(:public?).returns(false)
    User.any_instance.stubs(:admin?).returns(false)
    User.any_instance.expects(:permissions).returns(stub(:paths_for => %w(foo)))
    expect_paginate_by_paths [], %w(foo)
    login_as :rick
    get :index
    assert_template 'index'
  end

  private
    def expect_paginate(value = [])
      changesets = stub
      changesets.expects(:paginate).returns(value)
      Repository.any_instance.expects(:changesets).returns(changesets)
    end

    def expect_paginate_by_paths(value = [], paths = [], page = nil)
      changesets = stub
      changesets.expects(:paginate_by_paths).with(paths, :page => page, :order => 'changesets.revision desc').returns(value)
      Repository.any_instance.expects(:changesets).returns(changesets)
    end
end
