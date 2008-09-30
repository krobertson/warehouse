require File.dirname(__FILE__) + '/../test_helper'
require 'browser_controller'

# Re-raise errors caught by the controller.
class BrowserController
  def rescue_action(e) raise e end
  def check_for_valid_domain() end
end


context "Browser Controller Permissions" do
  def setup
    @controller = BrowserController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "sample.test.host"
    Repository.any_instance.stubs(:backend).returns(true)
    class << @controller
      def status_message(type, message = nil, template = nil)
        render :text => "#{type}: #{message.inspect}"
        false
      end

      def repository_member_required_with_testing
        repository_member_required_without_testing
        render :text => 'passed' unless performed?
        false
      end
      alias_method_chain :repository_member_required, :testing
    end
  end
  
  specify "should accept anonymous public repo" do
    @controller.stubs(:current_repository).returns(repositories(:sample))
    @controller.stubs(:current_user).returns(nil)
    repositories(:sample).stubs(:public?).returns(true)
    repositories(:sample).stubs(:node).returns(stub_node)
    get :index, :paths => []
    assert_match /^passed/, @response.body
  end
  
  specify "should accept anonymous to public repo" do
    @controller.stubs(:current_repository).returns(repositories(:sample))
    @controller.stubs(:current_user).returns(nil)
    repositories(:sample).stubs(:public?).returns(true)
    repositories(:sample).stubs(:node).returns(stub_node)
    get :index, :paths => []
    assert_match /^passed/, @response.body
  end
  
  specify "should accept full admin to repo" do
    @controller.stubs(:current_repository).returns(repositories(:sample))
    @controller.stubs(:current_user).returns(users(:rick))
    repositories(:sample).stubs(:public?).returns(false)
    repositories(:sample).stubs(:node).returns(stub_node)
    get :index, :paths => []
    assert_match /^passed/, @response.body
  end
  
  specify "should accept member to repo" do
    @controller.stubs(:current_repository).returns(repositories(:sample))
    @controller.stubs(:current_user).returns(stub(:id => users(:rick).id, :admin? => false))
    repositories(:sample).stubs(:public?).returns(false)
    repositories(:sample).stubs(:node).returns(stub_node)
    get :index, :paths => []
    assert_match /^passed/, @response.body
  end
  
  specify "should require valid path for member to repo" do
    Permission.update_all ['path = ?', 'public']
    @controller.stubs(:current_repository).returns(repositories(:sample))
    @controller.stubs(:current_user).returns(stub(:id => users(:rick).id, :admin? => false))
    repositories(:sample).stubs(:public?).returns(false)
    repositories(:sample).stubs(:node).returns(stub_node('/'))
    get :index, :paths => []
    assert_match /^error/, @response.body
  end
  
  specify "should accept exact path for member to repo" do
    Permission.update_all ['path = ?', 'public']
    @controller.stubs(:current_repository).returns(repositories(:sample))
    @controller.stubs(:current_user).returns(stub(:id => users(:rick).id, :admin? => false))
    repositories(:sample).stubs(:public?).returns(false)
    repositories(:sample).stubs(:node).returns(stub_node('public'))
    get :index, :paths => %w(public)
    assert_match /^passed/, @response.body
  end
  
  specify "should accept sub path for member to repo" do
    Permission.update_all ['path = ?', 'public']
    @controller.stubs(:current_repository).returns(repositories(:sample))
    @controller.stubs(:current_user).returns(stub(:id => users(:rick).id, :admin? => false))
    repositories(:sample).stubs(:public?).returns(false)
    repositories(:sample).stubs(:node).returns(stub_node('public/foo'))
    get :index, :paths => %w(public/foo)
    assert_match /^passed/, @response.body
  end
  
  specify "should accept sub file for member to repo" do
    Permission.update_all ['path = ?', 'public']
    @controller.stubs(:current_repository).returns(repositories(:sample))
    @controller.stubs(:current_user).returns(stub(:id => users(:rick).id, :admin? => false))
    repositories(:sample).stubs(:public?).returns(false)
    repositories(:sample).stubs(:node).returns(stub_node('public/foo.txt', :dir? => true))
    get :index, :paths => %w(public/foo.txt)
    assert_match /^passed/, @response.body
  end
end
