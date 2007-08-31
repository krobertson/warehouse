require File.dirname(__FILE__) + '/../test_helper'

Warehouse::Plugins # load lib/warehouse/plugins
module Warehouse
  module Plugins
    class Whatever < Warehouse::Plugins::Base
    end
  end
end

context "Plugin" do
  fixtures :plugins

  specify "should find plugins in filesystem" do
    Warehouse::Plugins.find_in(Plugin.plugin_path).should == %w(bar foo)
  end
  
  specify "should find loaded plugins" do
    Plugin.find_from(%w(foo bar)).should == [plugins(:foo)]
  end
  
  specify "should create empty plugin record" do
    assert_difference "Plugin.count" do
      plugin = Plugin.create_empty_for('whatever')
      plugin.name.should == 'whatever'
    end
  end
  
  specify "should create empty plugin record from class" do
    plugin = Plugin.create_empty_for(Warehouse::Plugins::Whatever)
    plugin.name.should == 'whatever'
  end
  
  specify "should not return plugin class for inactive plugin" do
    plugin = Plugin.new :name => 'whatever'
    plugin.plugin_class.should.be.nil
  end
  
  specify "should return plugin class for active plugin" do
    plugin = Plugin.new :name => 'whatever', :active => true
    plugin.plugin_class.should == Warehouse::Plugins::Whatever
  end
end

context "Plugin (discovery)" do
  fixtures :plugins

  setup do
    Warehouse::Plugins.index.clear
    Warehouse::Plugins.discovered.clear
    Warehouse::Plugins.discover Plugin.plugin_path
  end
  
  specify "should create empty plugin" do
    bar = Plugin.find_by_name 'bar'
    bar.active = true
    bar.plugin_class.should == Warehouse::Plugins::Bar
  end
  
  specify "should list discovered plugins" do
    Warehouse::Plugins.discovered[0].name.should == 'bar'
    Warehouse::Plugins.discovered[1].name.should == 'foo'
  end
  
  specify "should index plugins" do
    Warehouse::Plugins.index['foo'].name.should == 'foo'
    Warehouse::Plugins.index['bar'].name.should == 'bar'
  end
end
