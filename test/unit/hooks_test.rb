require File.join(File.dirname(__FILE__), '..', 'test_helper')
HOOK_ROOT = File.join(RAILS_ROOT, 'vendor', 'plugins', 'hooks')
Warehouse::Hooks.discover HOOK_ROOT

context "Hooks" do
  specify "should define hook class with multiple methods" do
    begin
      Warehouse::Hooks.const_defined?(:HookMultipleMethods).should == false
      
      Warehouse::Hooks.define :hook_multiple_methods do
        receiver { 'bob' }
        run      { "hi #{receiver}" }
      end
      
      Warehouse::Hooks::HookMultipleMethods.new(stub(:repo => nil)).run.should == 'hi bob'
      
      Warehouse::Hooks.const_defined?(:HookMultipleMethods).should == true
    ensure
      Warehouse::Hooks.send(:remove_const, :HookMultipleMethods) if Warehouse::Hooks.const_defined?(:HookMultipleMethods)
    end
  end
end

context "Base" do
  setup do
    Warehouse::Hooks.define :hook_test do
      run { 'this was a test' }
    end
  end
  
  teardown do
    Warehouse::Hooks.send :remove_const, :HookTest
  end
  
  specify "should check validity of hook" do
    commit = stub(:dirs_changed => %w(foo/bar foo baz).join("\n"), :repo => nil)
    Warehouse::Hooks::HookTest.new(commit).should.be.valid
    Warehouse::Hooks::HookTest.new(commit, :prefix => '').should.be.valid
    Warehouse::Hooks::HookTest.new(commit, :prefix => 'foo').should.be.valid
    Warehouse::Hooks::HookTest.new(commit, :prefix => '^foo').should.be.valid
    Warehouse::Hooks::HookTest.new(commit, :prefix => '/baz').should.be.valid
    Warehouse::Hooks::HookTest.new(commit, :prefix => '/^baz/').should.be.valid
    Warehouse::Hooks::HookTest.new(commit, :prefix => 'bar').should.not.be.valid
    Warehouse::Hooks::HookTest.new(commit, :prefix => '/^bar').should.not.be.valid
  end
end

context "Discovered" do
  setup do
    Warehouse::Hooks.discovered.clear
    Warehouse::Hooks.index.clear
  end
  
  specify "should find discovered hooks" do
    Warehouse::Hooks.discover.should == [Warehouse::Hooks::Foo]
  end
  
  specify "should replace with repository hook" do
    hook = Hook.new :name => 'foo'
    repository = stub
    repository.expects(:hooks).returns([hook])
    Warehouse::Hooks.for(repository).should == [hook]
  end
  
  specify "should not replace with other repository hook" do
    hook = Hook.new :name => 'foo2'
    repository = stub
    repository.expects(:hooks).returns([hook])
    Warehouse::Hooks.for(repository).should == [Warehouse::Hooks::Foo]
  end
end

context "Commit" do
  %w(author dirs_changed log changed).each do |attr|
    specify "#{attr} should expire" do
      commit = Warehouse::Hooks::Commit.new(nil, '', 1)
      commit.expects(:svnlook).returns(5)
      2.times { commit.send(attr).should == 5 }
    end
  end
  
  specify "should only run valid hooks" do
    ValidHook.any_instance.expects(:run!)
    Warehouse::Hooks::Commit.run nil, '', 1, [[ValidHook, {}], [InvalidHook, {}]]
  end
end

Warehouse::Hooks.discovered.each do |hook|
  test_file = File.join(HOOK_ROOT, hook.plugin_name, 'test')
  require test_file if File.exist?(test_file + '.rb')
end

class ValidHook
  def valid?() true end
  def initialize(commit, options) end
  def run() end
end

class InvalidHook < ValidHook
  def valid?() false end
  def run!() raise end
end