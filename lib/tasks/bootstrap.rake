namespace :warehouse do
  task :bootstrap => :init_highline do
    say "Bootstrapping Warehouse v#{Warehouse.version}..."
    puts
    say "1) Check for subversion bindings and proper permissions"
    say "2) Create Database.yml config file"
    say "3) Load Database Schema"
    puts

    begin
      say "checking for subversion bindings..."
      require 'svn/core'
      say "... found it!"
    rescue
      say "You do not have the ruby/svn bindings installed."
      raise
    end
    
    say "checking for proper write permissions..."
    if File.writable?('config/initializers')
      say "... looks good!"
    else
      say "The config/initializers directy should be writable to rails so Warehouse can store this copy's configuration."
      return
    end
    
    puts
    say "Step 1 is complete, now to check your database.yml file."
    puts

    if File.exist?('config/database.yml')
      say "It looks like you already have a database.yml file."
      if agree("Would you like to CLEAR it and start over? [y/n]")
        rm 'config/database.yml'
      end
    end
    
    unless File.exist?('config/database.yml')
      if agree("Would you like to create a database.yml file? [y/n]")
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
        puts
        options.host     = ask("Host name: (default = localhost)")
        puts
        say "This same database will be used for your DEV and PRODUCTION environments."
        say "The test database name will be inferred from this database name."
        options.database = ask("Database name:")
        puts
        options.username = ask("User name:")
        puts
        options.password = ask("Password:") { |q| q.echo = "x" }
        puts
        options.socket   = ask("Socket path: (blank by default)")
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
        say "Your databases:"
        say "Development: '#{options.database}'"
        say "Production:  '#{options.database}'"
        say "Test:        '#{options.test_database}'"
        say "I don't quite feel comfortable creating your database for you (I hardly know you).  So, make sure these databases have been created before proceeding."
      else
        cp 'config/database.sample.yml', 'config/database.yml'
        say "I have copied database.sample.yml over.  Now, edit config/database.yml with your correct database settings."
        return
      end
    end

    puts
    unless agree("Now it's time for Step 3: Load the database schema.  All of your data will be overwritten. Are you sure you wish to continue? [y/n]")
      raise "Cancelled"
    end
    puts

    mkdir_p File.join(RAILS_ROOT, 'log')
    warehouse_path = File.join(RAILS_ROOT, 'config', 'initializers', 'warehouse.rb')
    rm warehouse_path if File.exist?(warehouse_path)
    
    %w(environment db:schema:load tmp:create).each { |t| Rake::Task[t].execute }
    
    say '=' * 80
    puts
    say "Warehouse v#{Warehouse.version} is ready to roll."
    say "Okay, thanks for bootstrapping!  I know I felt some chemistry here, did you?"
    say "Now, start the application with 'script/server' and visit http://mydomain.com/ to start the installation process."
    puts
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
    require 'lib/warehouse'
    
    $terminal = HighLine.new
    class << self
      extend Forwardable
      def_delegators :$terminal, :agree, :ask, :choose, :say
    end
  end
end