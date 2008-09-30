USE_REPO_PATHS  = ENV['USE_REPO_PATHS'] unless Object.const_defined?(:USE_REPO_PATHS)
REPO_ROOT_REGEX = /^(\/?(admin|changesets|browser|install|login|logout|reset|forget))(\/|$)/

ActionController::Routing::Routes.draw do |map|
  map.connect ":asset/:plugin/*paths", :asset => /images|javascripts|stylesheets/, :controller => "assets", :action => "show"

  map.diff "changesets/diff/:rev/*paths", :controller => "changesets", :action => "diff", :rev => /r\d+/

  map.resources :changesets, :has_many => :changes, :collection => { :public => :get }
  
  map.with_options :path_prefix => 'admin' do |admin|
    admin.resources :bookmarks
    admin.resources :plugins
    admin.resources :hooks
    admin.resources :permissions, :collection => { :anon => :any }
    admin.resources :users, :has_one => [:permissions]
    admin.resource  :profile, :controller => "users"
    admin.resources :repositories, :member => { :sync => :any }
  end

  map.with_options :controller => 'changesets', :action => 'index' do |m|
    m.root_changesets                  'changesets'
    m.formatted_root_changesets        'changesets.:format', :format => 'xml'
    m.root_public_changesets           'changesets/public', :action => 'public'
    m.formatted_root_public_changesets 'changesets/public.:format', :action => 'public', :format => 'xml'
  end

  map.with_options :controller => "browser" do |b|
    b.rev_browser "browser/:rev/*paths", :rev => /r\d+/
    b.browser     "browser/*paths"
    b.blame       "blame/*paths", :action => "blame"
    b.text        "text/*paths",  :action => "text"
    b.raw         "raw/*paths",   :action => "raw"
  end
  
  map.with_options :controller => "sessions" do |s|
    s.login   "login",        :action => "create"
    s.logout  "logout",       :action => "destroy"
    s.forget  "forget",       :action => "forget"
    s.reset   "reset/:token", :action => "reset", :token => nil
  end

  map.history  "history/*paths", :controller => "history"
  map.admin    "admin",          :controller => "repositories"
  map.settings "admin/settings", :controller => "install", :action => "settings"

  map.installer "install", :controller => "install", :action => "index",   :conditions => { :method => :get  }
  map.connect   "install", :controller => "install", :action => "install", :conditions => { :method => :post }
  
  if RAILS_ENV == "development"
    map.connect "test_install", :controller => "install", :action => "test_install"
  end

  map.root :controller => "dashboard"
end