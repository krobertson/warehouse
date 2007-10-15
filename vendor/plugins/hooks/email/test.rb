require File.dirname(__FILE__) + '/../test_helper'
load_hook :email

context "Email" do
  before do
    @repo    = {:id => 1, :subdomain => 'foo'}
    @commit  = stub(:revision => 5, :changed => ['M foo', 'A foo/bar'].join("\n"), :author => 'rick', :log => "add bar\n * one\n * two", :changed_at => Time.utc(2007, 1, 1), :repo => @repo)
    @options = {}
    @hook    = Warehouse::Hooks::Email.new(@commit, @options)
  end
  
  it "should split first commit line" do
    @hook.first_commit_line.should == 'add bar'
  end
  
  it "should split extended commit lines" do
    @hook.extended_commit_lines.should == [' * one', ' * two']
  end
  
  it "should create basic subject line" do
    @hook.subject.should == "5: add bar"
  end
  
  it "should create prefixed subject line" do
    @hook.options[:subject_prefix] = 'foo'
    @hook.subject.should == "[foo] 5: add bar"
  end
end