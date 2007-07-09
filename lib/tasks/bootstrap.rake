namespace :warehouse do
  task :upgrade => :check_structure do
    unless @in_structure || ENV['WAREHOUSE_FORCE']
      say "Warehouse is not setup to upgrade."
      say "Try running 'rake warehouse:setup'"
      return
    end
    
    rel_path = "releases/warehouse-#{Warehouse.version}"

    Dir.chdir '../..'
    Dir['shared/**/**'].each do |file|
      next unless file =~ /^shared\/config/
      rel_file = file.gsub /shared/, rel_path
      next unless File.file?(file)
      ln_sf File.expand_path(file), File.dirname(rel_file)
    end
    ln_sf File.expand_path("shared/public/avatars"), File.join(rel_path, 'public', 'avatars')
    ln_sf File.expand_path(rel_path), 'current'
    Dir.chdir rel_path
    
    unless ENV['WAREHOUSE_FORCE']
      say "Upgraded to v#{Warehouse.version}"
      say "Be sure to restart the Rails application to see the changes take effect."
    end
  end
  
  task :check_structure => :init_highline do
    @app_root = Pathname.new(Dir.pwd)
    
    @in_structure = \
      (@app_root.dirname.basename.to_s == 'releases') && 
      (@app_root.dirname.dirname + 'shared').exist?
  end
  
  task :setup => :check_structure do
    if @in_structure
      say "Warehouse is already setup correctly."
    else      
      top_level = ENV['TOP_LEVEL'] || 'warehouse'
      rel_path = "releases/warehouse-#{Warehouse.version}"
      say "It doesn't look like Warehouse is setup in the recommended structure:"
      puts
      say "#{@app_root.dirname}/#{top_level}/shared <-- shared config files"
      say "#{@app_root.dirname}/#{top_level}/#{rel_path} <-- this warehouse release"
      say "#{@app_root.dirname}/#{top_level}/current <-- symlink of latest warehouse release"
      puts
      say "The added benefits are simpler Web Server configuration and upgradeability."
      puts
      if agree("Would you like to setup Warehouse like this? [y/n]")
        rel_files = ['config/database.yml', 'config/initializers/warehouse.rb', 'public/avatars'].inject({}) do |memo, path|
          memo.update path => File.expand_path(path)
        end

        mkdir_p "../#{top_level}"
        Dir.chdir "../#{top_level}"
        mkdir_p 'shared/config/initializers'
        mkdir_p 'shared/public'
        mkdir_p 'releases'
        rel_files.each do |path, full|
          next unless File.exist?(full)
          cp_r full, File.join('shared', path)
        end
        touch 'shared/config/initializers/warehouse.rb' unless File.exist?('shared/config/initializers/warehouse.rb')
        touch 'shared/config/database.yml'              unless File.exist?('shared/config/database.yml')
        mkdir_p 'shared/public/avatars'
        mv @app_root.to_s, rel_path
        
        Dir.chdir rel_path
        ENV['WAREHOUSE_FORCE'] = '1'
        Rake::Task["warehouse:upgrade"].execute
      end
    end
  end
  
  task :bootstrap => :check_structure do
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

    db_config = "config/database.yml"
    db_config = File.readlink(db_config) if File.symlink?(db_config)
    
    if File.exist?(db_config)
      say "It looks like you already have a database.yml file."
      @restart = agree("Would you like to CLEAR it and start over? [y/n]")
    end
    
    unless !@restart && File.exist?(db_config)
      if @restart || agree("Would you like to create a database.yml file? [y/n]")
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
        File.open File.expand_path(db_config), 'w' do |f|
          f.write erb.result(options.get_binding)
        end
        say "Your databases:"
        say "Development: '#{options.database}'"
        say "Production:  '#{options.database}'"
        say "Test:        '#{options.test_database}'"
        say "I don't quite feel comfortable creating your database for you (I hardly know you).  So, make sure these databases have been created before proceeding."
      else
        cp 'config/database.sample.yml', db_config
        say "I have copied database.sample.yml over.  Now, edit #{db_config} with your correct database settings."
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
    unless $terminal
      RAILS_ENV = 'production'
      $LOAD_PATH << 'vendor/highline-1.2.9/lib'
      require 'ostruct'
      require 'pathname'
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
end