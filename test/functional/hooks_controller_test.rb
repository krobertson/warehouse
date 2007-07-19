require File.dirname(__FILE__) + '/../test_helper'
require 'hooks_controller'

# Re-raise errors caught by the controller.
class HooksController; def rescue_action(e) raise e end; end

class HooksControllerTest < Test::Unit::TestCase
  def setup
    @controller = HooksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
