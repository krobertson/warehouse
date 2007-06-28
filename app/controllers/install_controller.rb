class InstallController < ApplicationController
  skip_before_filter :check_for_valid_domain
  skip_before_filter :check_for_repository
  before_filter :check_installed, :except => [:test_install, :settings]
  
  before_filter :admin_required, :only => :settings
  
  layout :choose_layout

  def index
    if session[:installing]
      @repository = Repository.find(:first)
      session[:installing] = nil
      authenticate_with_open_id do |result, identity_url|
        if result.successful? && self.current_user = User.find_or_create_by_identity_url(identity_url)
          render :action => 'install'
        else
          @message = result.message || "Sorry, no user by that identity URL exists (#{identity_url})"
          render :action => 'index'
        end
      end
    else
      @repository = Repository.new
    end
  end
  
  def install
    unless !params[:domain].blank? && params[:domain] =~ evil_regex
      raise "bad domain!"
    end

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
    
    if @repository.save
      session[:installing] = true
      authenticate_with_open_id
    else
      render :action => 'index'
    end
  rescue
    @message = $!.message
    render :template => 'layouts/error'
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

      File.open(File.join(RAILS_ROOT, 'config', 'initializers', 'warehouse.rb'), 'w') do |f|
        f.write tmpl.join("\n")
      end
      
      session(Warehouse.session_options) if domain_is_blank && !attributes[:domain].blank?
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
