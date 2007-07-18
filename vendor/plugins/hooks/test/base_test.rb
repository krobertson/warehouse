require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

context "Base" do
  specify "should check validity of hook" do
    commit = stub(:dirs_changed => %w(foo/bar foo baz).join("\n"))
    Warehouse::Hooks::Base.new(commit).should.be.valid
    Warehouse::Hooks::Base.new(commit, :prefix => '').should.be.valid
    Warehouse::Hooks::Base.new(commit, :prefix => /^foo/).should.be.valid
    Warehouse::Hooks::Base.new(commit, :prefix => /^baz/).should.be.valid
    Warehouse::Hooks::Base.new(commit, :prefix => /^bar/).should.not.be.valid
  end
end