namespace :warehouse do
  task :bootstrap => :init_highline do
    unless File.exist?('config/database.yml')
      if agree("You are missing a database.yml file.  Would you like to create one now?")
        options = OpenStruct.new
        class << options
          def get_binding() binding end
          def test_database
            @test_database ||= database.gsub(pattern, '') + '_test'
          end
        end
        options.keys     = [:adapter, :host, :database, :username, :password, :socket]
        options.pattern  = /_(dev.*|prod.*|test)$/
        options.adapter  = 'mysql'
        options.host     = ask("What host is the database on? (default = localhost)")
        options.database = ask("What is the database name? (warehouse, my_warehouse, my_warehouse_production are all good choices)")
        options.username = ask("What is the database's user name?")
        options.password = ask("What is the database user's password?") { |q| q.echo = "x" }
        options.socket   = ask("What is the socket path? (blank by default)")
        [:host, :socket].each do |attr|
          if options.send(attr).to_s.size == 0
            options.delete_field(attr)
            options.keys.delete(attr)
          end
        end
        require 'erb'
        erb = ERB.new(IO.read(File.join(RAILS_ROOT, 'config', 'database.erb')), nil, '<>')
        File.open File.join(RAILS_ROOT, 'config', 'database.yml'), 'w' do |f|
          f.write erb.result(options.get_binding)
        end
        say "I used the '#{options.database}' database for your development and production environments, and '#{options.test_database}' for testing.  If you haven't already, now would be a good time to create them."
      else
        say "I have copied database.sample.yml over.  Now, edit config/database.yml with your correct database settings."
        cp 'config/database.sample.yml', 'config/database.yml'
        return
      end
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

    mkdir_p File.join(RAILS_ROOT, 'log')
    warehouse_path = File.join(RAILS_ROOT, 'config', 'initializers', 'warehouse.rb')
    rm warehouse_path if File.exist?(warehouse_path)
    
    %w(environment db:schema:load tmp:create).each { |t| Rake::Task[t].execute }
    
    say '=' * 80

    say "Warehouse v#{Warehouse.version} is ready to roll.  Now, start the application with 'script/server' and visit"
    say "http://mydomain.com/ to start the installation process."

    say "For help, visit the following:"
    say "  Official Warehouse Site - http://warehouseapp.com"
    say "  The Active Reload Forum - http://forum.activereload.net"
    say "  ActiveReload on IRC (Freenode): #activereload"
  end
  
  task :init_highline do
    RAILS_ENV = 'production'
    $LOAD_PATH << 'vendor/highline-1.2.9/lib'
    require 'ostruct'
    require "highline"
    require "forwardable"
    
    $terminal = HighLine.new
    class << self
      extend Forwardable
      def_delegators :$terminal, :agree, :ask, :choose, :say
    end
  end
end