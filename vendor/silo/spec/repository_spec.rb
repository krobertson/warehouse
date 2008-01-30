require File.join(File.dirname(__FILE__), 'spec_helper')
load_adapter!

describe Silo::Repository do
  before do
    @repo = Silo::Repository.new($adapter_type, $adapter_options[$adapter_type])
  end
  
  it "creates node for given path" do
    node = @repo.node_at '/foo'
    node.repository.should == @repo
    node.path.should == 'foo'
    node.revision.should == 5
  end
  
  it "creates node for given path and revision" do
    node = @repo.node_at '/foo', 9
    node.repository.should == @repo
    node.path.should == 'foo'
    node.revision.should == 9
  end
end