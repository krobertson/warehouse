require File.dirname(__FILE__) + '/../test_helper'
require 'repositories_controller'

# Re-raise errors caught by the controller.
class RepositoriesController; def rescue_action(e) raise e end; end

class RepositoriesControllerTest < Test::Unit::TestCase
  def setup
    @controller = RepositoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
