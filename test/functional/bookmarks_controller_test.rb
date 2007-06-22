require File.dirname(__FILE__) + '/../test_helper'
require 'bookmarks_controller'

# Re-raise errors caught by the controller.
class BookmarksController
  def rescue_action(e) raise e end
  def check_for_valid_domain() end
end


context "Bookmarks Controller" do
  setup do
    @controller = BookmarksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  specify "should create new bookmark" do
    @controller.stubs(:current_user).returns(users(:rick))
    @request.host = "sample.test.host"
    assert_difference "Bookmark.count" do
      post :create, :bookmark => { :path => 'foo', :label => 'Foo' }
    end
  end

  specify "should destroy bookmark" do
    @controller.stubs(:current_user).returns(users(:rick))
    @request.host = "sample.test.host"
    assert_difference "Bookmark.count", -1 do
      delete :destroy, :id => 1
    end
  end
  
  specify "should not allow duplicate paths" do
    @controller.stubs(:current_user).returns(users(:rick))
    @request.host = "sample.test.host"
    assert_no_difference "Bookmark.count" do
      post :create, :bookmark => { :path => 'moon', :label => 'Foo' }
    end
  end
  
  specify "should require repository_admin" do
    @controller.stubs(:current_user).returns(users(:justin))
    @request.host = "sample.test.host"
    assert_no_difference "Bookmark.count" do
      post :create, :bookmark => { :path => 'foo', :label => 'Foo' }
    end
  end
  
  specify "should not see bookmark in other repo" do
    @controller.stubs(:current_user).returns(users(:rick))
    @request.host = "example.test.host"
    assert_raises ActiveRecord::RecordNotFound do
      delete :destroy, :id => 1
    end
  end
end
