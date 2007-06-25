require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController
  def rescue_action(e) raise e end
  def check_for_valid_domain() end
end


context "Users Controller" do
  def setup
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
    end
  end

  xspecify "should require logged_in user" do
    login_as nil
    get :show
    assert_match /^error/, @response.body
  end
  
  xspecify "should accept valid user" do
    login_as :rick
    get :show, :id => users(:rick).id.to_s
    assert_match /^passed/, @response.body
  end
  
  xspecify "should accept implicit user" do
    login_as :rick
    get :show
    assert_match /^passed/, @response.body
  end
end
