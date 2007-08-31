desc "freeze rails edge"

task :test do
  Rake::Task['test:hooks'].invoke
  Rake::Task['test:commands'].invoke
end

namespace :test do
  Rake::TestTask.new :hooks do |t|
    t.libs << 'test'
    t.pattern = 'vendor/plugins/hooks/test/*_test.rb'
    t.verbose = true
  end

  Rake::TestTask.new :commands do |t|
    t.libs << 'test'
    t.pattern = 'test/commands/*_test.rb'
    t.verbose = true
  end
end

require 'code_statistics'
STATS_DIRECTORIES.insert 3, %w(Cachers     app/cachers)
STATS_DIRECTORIES.insert 4, %w(Concerns    app/concerns)
STATS_DIRECTORIES.insert 5, %w(Hooks       vendor/plugins/hooks/lib)
STATS_DIRECTORIES.insert 6, %w(Hook\ tests vendor/plugins/hooks/test)
STATS_DIRECTORIES << %w(Command\ tests     test/commands)
CodeStatistics::TEST_TYPES << 'Command tests' << 'Hook tests'

task :edge do
  ENV['SHARED_PATH']  = '../../shared' unless ENV['SHARED_PATH']
  ENV['RAILS_PATH'] ||= File.join(ENV['SHARED_PATH'], 'rails')
  
  checkout_path = File.join(ENV['RAILS_PATH'], 'trunk')
  export_path   = "#{ENV['RAILS_PATH']}/rev_#{ENV['REVISION']}"
  symlink_path  = 'vendor/rails'

  unless File.exists?(ENV['RAILS_PATH'])
    mkdir_p ENV['RAILS_PATH']
  end

  # do we need to checkout the file?
  unless File.exists?(checkout_path)
    puts 'setting up rails trunk'    
    get_framework_for checkout_path do |framework|
      system "svn co http://dev.rubyonrails.org/svn/rails/trunk/#{framework}/lib #{checkout_path}/#{framework}/lib --quiet"
    end
  end

  # do we need to export the revision?
  unless File.exists?(export_path)
    puts "setting up rails rev #{ENV['REVISION']}"
    get_framework_for export_path do |framework|
      system "svn up #{checkout_path}/#{framework}/lib -r #{ENV['REVISION']} --quiet"
      system "svn export #{checkout_path}/#{framework}/lib #{export_path}/#{framework}/lib"
    end
  end

  puts 'linking rails'
  rm_rf   symlink_path
  mkdir_p symlink_path

  get_framework_for symlink_path do |framework|
    ln_s File.expand_path("#{export_path}/#{framework}/lib"), "#{symlink_path}/#{framework}/lib"
  end
  
  touch "vendor/rails_#{ENV['REVISION']}"
end

def get_framework_for(*paths)
  %w( railties actionpack activerecord actionmailer activesupport activeresource actionwebservice ).each do |framework|
    paths.each { |path| mkdir_p "#{path}/#{framework}" }
    yield framework
  end
end