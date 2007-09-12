require File.dirname(__FILE__) + '/../test_helper'
require 'plugins_controller'

# Re-raise errors caught by the controller.
class PluginsController; def rescue_action(e) raise e end; end

context "Plugins Controller" do
  fixtures :plugins
  setup do
    @controller = PluginsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :rick
  end

  specify "should edit plugin attributes" do
    put :update, :id => 2, :plugin => {'foo' => 'bar'}
    plugins(:inactive).options.should == {'foo' => 'bar'}
  end

  specify "should activate plugin" do
    plugins(:inactive).should.not.be.active
    put :update, :id => 2, :plugin => {:active => '1'}
    plugins(:inactive).reload.should.be.active
  end

  specify "should deactivate plugin" do
    plugins(:foo).should.be.active
    put :update, :id => 1, :plugin => {:active => '0'}
    plugins(:foo).reload.should.not.be.active
  end
end
