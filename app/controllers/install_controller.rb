require 'digest/sha1'
class InstallController < ApplicationController
  @@install_path = File.join(RAILS_ROOT, 'config', 'installs')
  skip_before_filter :check_for_valid_domain
  skip_before_filter :check_for_repository
  before_filter :check_installed, :except => [:test_install, :settings]
  
  before_filter :admin_required, :only => :settings
  
  layout :choose_layout

  def index
    @repository = Repository.new(params[:repository])
    @user       = User.new(params[:user])
  end
  
  def install
    index
    unless @repository.valid? && @user.valid?
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
      @user.save!
    end
  rescue
    @message = $!.message
    logger.warn $!.message
    $!.backtrace.each { |b| logger.warn "> #{b}" }
    render :action => 'index'
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
end
