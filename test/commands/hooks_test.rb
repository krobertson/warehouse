require File.dirname(__FILE__) + '/../test_helper'
Warehouse::Command.configure(ActiveRecord::Base.configurations['test'].symbolize_keys)

context "Post Commit Hooks" do
  setup do
    @command = Warehouse::Command.new
  end

  specify "should be filtered by repository" do
    hooks = @command.send(:hooks_for, :id => 1).to_a
    hooks.size.should == 1
    hooks.first[:id] == hooks(:sample_lighthouse).id
  end
  
  specify "should index hooks for commit" do
    options = [{'a' => 1}, {'b' => 2}]
    indexed = @command.send :indexed_hooks, 
      [{:name => 'lighthouse', :options => options[0].to_yaml}, 
       {:name => 'lighthouse', :options => options[1].to_yaml}]
    indexed.size.should == 2
    indexed[0][0].should == Warehouse::Hooks::Lighthouse
    indexed[0][1].should == options[0]
    indexed[1][0].should == Warehouse::Hooks::Lighthouse
    indexed[1][1].should == options[1]
  end
end