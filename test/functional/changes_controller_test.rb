require File.dirname(__FILE__) + '/../test_helper'
require 'changes_controller'

# Re-raise errors caught by the controller.
class ChangesController; def rescue_action(e) raise e end; end

context "Changes Controller" do
  setup do
    @controller = ChangesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "sample.test.host"
  end
  
  specify "should redirect index to changesets controller" do
    get :index, :changeset_id => 1
    assert_redirected_to changeset_path(:id => 1)
  end
  
  specify "should allow accessible to view change" do
    Change.any_instance.expects(:accessible_by?).returns(true)
    Change.any_instance.expects(:diffable?).returns(false)
    get :show, :changeset_id => 1, :id => 2
    assert_template 'show'
  end
  
  specify "should not allow inaccessible to view change" do
    Change.any_instance.expects(:accessible_by?).returns(false)
    get :show, :changeset_id => 1, :id => 2
    assert_template 'layouts/error'
  end
end
