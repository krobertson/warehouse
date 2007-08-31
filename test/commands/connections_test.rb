require File.dirname(__FILE__) + '/../test_helper'
Warehouse::Command.configure(ActiveRecord::Base.configurations['test'].symbolize_keys)

context "Command connections" do
  specify "should build correct sequel connection string from activerecord config hash" do
    Warehouse::Command.yaml_to_connection_string(:adapter => 'mysql', :username => 'rick', :password => 'secret', :host => 'myhost', :database => 'test').should == \
      "mysql://rick:secret@myhost/test"
  end

  specify "should build correct sequel connection string from activerecord config hash without host value" do
    Warehouse::Command.yaml_to_connection_string(:adapter => 'mysql', :username => 'rick', :password => 'secret', :database => 'test').should == \
      "mysql://rick:secret@localhost/test"
  end

  specify "should build correct sequel connection string from activerecord config hash using postgresql" do
    Warehouse::Command.yaml_to_connection_string(:adapter => 'postgresql', :username => 'rick', :password => 'secret', :host => 'myhost', :database => 'test').should == \
      "postgres://rick:secret@myhost/test"
  end

  specify "should build correct sequel connection string from activerecord config hash using sqlite3" do
    Warehouse::Command.yaml_to_connection_string(:adapter => 'sqlite3', :username => 'rick', :password => 'secret', :host => 'myhost', :database => 'test').should == \
      "sqlite://test"
  end

  specify "should warn against sqlite2 usage" do
    assert_raises RuntimeError do
      Warehouse::Command.yaml_to_connection_string(:adapter => 'sqlite', :database => 'test')
    end
  end
end