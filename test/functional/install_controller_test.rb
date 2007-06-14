require File.dirname(__FILE__) + '/../test_helper'
require 'install_controller'

# Re-raise errors caught by the controller.
class InstallController; def rescue_action(e) raise e end; end

class InstallControllerTest < Test::Unit::TestCase
  def setup
    @controller = InstallController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
