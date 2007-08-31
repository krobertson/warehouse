require File.dirname(__FILE__) + '/../test_helper'

context "Post Commit Hooks" do
  fixtures :repositories, :hooks

  setup do
    @command = Warehouse::Command.new
  end

  specify "should be filtered by repository" do
    found_hooks = @command.send(:hooks_for, :id => 1).to_a
    found_hooks.size.should == 1
    found_hooks.first[:id] == hooks(:sample_lighthouse).id
  end
  
  specify "should index hooks for commit" do
    options = [{'a' => 1}, {'b' => 2}]
    indexed = @command.send :indexed_hooks, 
      [{:name => 'foo', :options => options[0].to_yaml}, 
       {:name => 'foo', :options => options[1].to_yaml}]
    indexed.size.should == 2
    indexed[0][0].should == Warehouse::Hooks::Foo
    indexed[0][1].should == options[0]
    indexed[1][0].should == Warehouse::Hooks::Foo
    indexed[1][1].should == options[1]
  end
end