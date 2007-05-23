require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

context "Users Controller" do
  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    class << @controller
      def access_denied(options = {})
        render :text => "error: #{options[:error].inspect}, redirect to #{options[:url].inspect}"
        false
      end

      def profile_required_with_testing
        profile_required_without_testing
        find_user
        render :text => 'passed' unless performed?
        false
      end
      alias_method_chain :profile_required, :testing
    end
  end

  specify "should require logged_in user" do
    @controller.stubs(:logged_in?).returns(false)
    get :show
    assert_match /^error/, @response.body
  end

  specify "should require correct user" do
    @controller.stubs(:current_user).returns(users(:rick))
    get :show, :id => '234'
    assert_match /^error/, @response.body
  end
  
  specify "should accept valid user" do
    @controller.stubs(:current_user).returns(users(:rick))
    get :show, :id => users(:rick).id.to_s
    assigns(:user).should == @controller.current_user
    assert_match /^passed/, @response.body
  end
  
  specify "should accept implicit user" do
    @controller.stubs(:current_user).returns(users(:rick))
    get :show
    assigns(:user).should == @controller.current_user
    assert_match /^passed/, @response.body
  end
end
