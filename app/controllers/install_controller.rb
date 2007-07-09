require 'digest/sha1'
class InstallController < ApplicationController
  @@install_path = File.join(RAILS_ROOT, 'config', 'installs')
  skip_before_filter :check_for_valid_domain
  skip_before_filter :check_for_repository
  before_filter :check_installed, :except => [:test_install, :settings]
  
  before_filter :admin_required, :only => :settings
  
  layout :choose_layout

  def index
    if using_open_id?
      authenticate_with_open_id do |result, identity_url|
        if result.successful?
          @install_file = File.join(@@install_path, "#{Digest::SHA1.hexdigest(identity_url)}.yml")
          if @install_data = @install_file && File.exist?(@install_file) && YAML.load_file(@install_file)
            params[:domain]     = @install_data[:domain]
            params[:license]    = @install_data[:license]
            params[:repository] = @install_data[:repository]

            @repository = Repository.new(params[:repository])
            unless @repository.valid?
              render :action => 'index'
              return
            end
    
            require 'net/http'
            res = Net::HTTP.post_form(URI.parse(Warehouse.forum_url % params[:license]), 'install[domain]' => params[:domain])
            if res.code != '200'
              raise res.body
            end

            write_config_file :domain => params[:domain]

            User.transaction do
              @repository.save!
              User.find_or_initialize_by_identity_url(identity_url).save!
            end
            render :action => 'install'
          else
            raise "No install file found"
          end
        else
          raise result.message || "Sorry, cannot create user by that identity URL exists (#{identity_url})"
        end
      end
    else
      @repository = Repository.new
    end
  rescue
    @message = $!.message
    logger.warn $!.message
    $!.backtrace.each { |b| logger.warn "> #{b}" }
    render :action => 'index'
  ensure
    FileUtils.rm @install_file if @install_data
  end
  
  def install
    FileUtils.mkdir_p @@install_path
    data = {:domain => params[:domain], 
      :license => params[:license],
      :repository => params[:repository]}
    File.open(File.join(@@install_path, "#{Digest::SHA1.hexdigest(OpenIdAuthentication.normalize_url(params[:openid_url]))}.yml"), 'w') do |f|
      f.write data.to_yaml
    end
    authenticate_with_open_id
  end

  def settings
    return unless request.post?
    write_config_file :domain => Warehouse.domain, :permission_command => params[:permission_command], :password_command => params[:password_command], :mail_from => params[:mail_from]
  end

  if RAILS_ENV == 'development'
    def test_install
      # @repository = Repository.new(:name => 'test', :path => '/foo/bar/baz')
      @repository = Repository.find(:first)
      render :action => 'install'
    end
  end
  
  protected
    def check_installed
      if current_repository && session[:installing].nil?
        redirect_to root_path
        false
      else
        true
      end
    end
    
    def write_config_file(attributes = {})
      domain_is_blank = Warehouse.domain.blank?
      tmpl = ['# This file is auto generated.  Visit /admin/settings to change it.', '#', "require 'warehouse' unless Object.const_defined?(:Warehouse)", '# set licensed domain name']
      attributes.each do |key, value|
        Warehouse.send "#{key}=", (value.blank? ? nil : value)
        tmpl << "Warehouse.#{key} = #{value.inspect}" unless value.blank?
      end

      wh_file = File.join(RAILS_ROOT, 'config', 'initializers', 'warehouse.rb')
      wh_file = File.readlink(wh_file) if File.symlink?(wh_file)
      File.open(File.join(RAILS_ROOT, 'config', 'initializers', 'warehouse.rb'), 'w') do |f|
        f.write tmpl.join("\n")
      end
      
      self.class.session(Warehouse.session_options) if domain_is_blank && !attributes[:domain].blank?
    end

    def choose_layout
      action_name == 'settings' ? 'application' : 'install'
    end

    # this regex is the stuff nightmares are made of
    # thanks to shaun inman
    # http://www.shauninman.com/archive/2006/05/08/validating_domain_names
    #
    # put down here because this monstrosity messed with textmate's syntax highlighting
    def evil_regex
      /^([a-z0-9]([-a-z0-9]*[a-z0-9])?\.)+((a[cdefgilmnoqrstuwxz]|aero|arpa)|(b[abdefghijmnorstvwyz]|biz)|(c[acdfghiklmnorsuvxyz]|cat|com|coop)|d[ejkmoz]|(e[ceghrstu]|edu)|f[ijkmor]|(g[abdefghilmnpqrstuwy]|gov)|(h[kmnrtu]#{RAILS_ENV=='test'?'|host':''})|(i[delmnoqrst]|info|int)|(j[emop]|jobs)|k[eghimnprwyz]|l[abcikrstuvy]|(m[acdghklmnopqrstuvwxyz]|mil|mobi|museum)|(n[acefgilopruz]|name|net)|(om|org)|(p[aefghklmnrstwy]|pro)|qa|r[eouw]|s[abcdeghijklmnortvyz]|(t[cdfghjklmnoprtvwz]|travel)|u[agkmsyz]|v[aceginu]|w[fs]|y[etu]|z[amw])$/
    end
end
