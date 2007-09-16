require File.dirname(__FILE__) + '/../test_helper'
Warehouse::Command.configure(ActiveRecord::Base.configurations['test'].symbolize_keys)

context "Command svn access config" do
  @@config = File.join(RAILS_ROOT, 'tmp', 'warehouse', 'config')
  setup do
    @command = Warehouse::Command.new
    FileUtils.mkdir_p File.dirname(@@config)
    FileUtils.rm_rf @@config
  end
  
  specify "should build config file" do
    expected = <<-END
[repo1:/]
* = r
rick = rw

[repo2:/foo]
* = rw
rick = r
END
    repo1 = {:id => 1, :subdomain => 'repo1', :path => 'foo/bar/repo1'}
    repo2 = {:id => 2, :subdomain => 'repo2', :path => 'foo/bar/repo2'}
    
    @command.expects(:grouped_permission_paths_for).with([repo1, repo2]).returns(
      {'1' => {'' => [
          {:path => '', :full_access => 0},
          {:path => '', :full_access => 1, :user_id => 1 }
        ]},
      '2' => {'foo' => [
          {:path => 'foo', :full_access => 1},
          {:path => 'foo', :full_access => 0, :user_id => 1 }
        ]}
      }
    )
    
    @command.build_config_for [repo1, repo2], @@config
    File.exist?(@@config).should == true
    IO.read(@@config).strip.should == expected.strip
  end
end