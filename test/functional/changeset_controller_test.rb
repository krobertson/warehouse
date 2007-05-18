require File.dirname(__FILE__) + '/../test_helper'
require 'changeset_controller'

# Re-raise errors caught by the controller.
class ChangesetController; def rescue_action(e) raise e end; end

class ChangesetControllerTest < Test::Unit::TestCase
  def setup
    @controller = ChangesetController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
