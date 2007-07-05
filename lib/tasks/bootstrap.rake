namespace :warehouse do
  task :bootstrap => :init_highline do
    unless File.exist?('config/database.yml')
      say "You are missing a database.yml file.  I have copied database.sample.yml over.  Now, edit database.yml with your correct database settings."
      cp 'config/database.sample.yml', 'config/database.yml'
      return
    end
    
    begin
      require 'svn/core'
    rescue
      say "You do not have the ruby/svn bindings installed."
      raise
    end
    
    unless File.writable?('config/initializers')
      say "The config/initializers directy should be writable to rails so Warehouse can store this copy's configuration."
      return
    end

    unless agree("This task will bootstrap your Warehouse install.  All of your data will be overwritten. Are you sure you wish to continue? [yes, no]")
      raise "Cancelled"
    end

    %w(environment db:schema:load tmp:create).each { |t| Rake::Task[t].execute }
    
    say '=' * 80

    say "Warehouse v#{Warehouse.version} is ready to roll.  Now, start the application with 'script/server' and visit"
    say "http://mydomain.com/ to start the installation process."

    say "For help, visit the following:"
    say "  Official Warehouse Site - http://warehouseapp.com"
    say "  The Active Reload Forum - http://forum.activereload.net"
    say "  ActiveReload on IRC (Freenode): #activereload"
    
    rm 'config/initializers/warehouse.rb' if File.exist?('config/initializers/warehouse.rb')
    mkdir_p File.join(RAILS_ROOT, 'log')
  end
  
  task :init_highline do
    RAILS_ENV = 'production'
    $LOAD_PATH << 'vendor/highline-1.2.9/lib'
    require "highline"
    require "forwardable"
    
    $terminal = HighLine.new
    class << self
      extend Forwardable
      def_delegators :$terminal, :agree, :ask, :choose, :say
    end
  end
end