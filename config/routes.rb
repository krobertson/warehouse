ActionController::Routing::Routes.draw do |map|
  map.resources :bookmarks, :plugins, :hooks
  map.resources :repositories, :member => { :sync => :any }
  map.resources :permissions, :collection => { :anon => :any }
  map.resources :users, :has_one => [:permissions]
  map.resources :changesets, :has_many => :changes, :collection => { :public => :get }
  map.resource  :profile, :controller => 'users'

  map.with_options :controller => 'browser' do |b|
    b.rev_browser 'browser/:rev/*paths', :rev => /r\d+/
    b.browser     'browser/*paths'
    b.text        'text/*paths', :action => 'text'
    b.raw         'raw/*paths',  :action => 'raw'
  end
  
  map.with_options :controller => 'sessions' do |s|
    s.login   'login',        :action => "create"
    s.logout  'logout',       :action => 'destroy'
    s.forget  'forget',       :action => 'forget'
    s.reset   'reset/:token', :action => 'reset', :token => nil
  end

  map.history  'history/*paths', :controller => 'history'
  map.admin    'admin',          :controller => 'repositories'
  map.settings 'admin/settings', :controller => 'install', :action => 'settings'

  map.installer 'install', :controller => 'install', :action => 'index',   :conditions => { :method => :get  }
  map.connect   'install', :controller => 'install', :action => 'install', :conditions => { :method => :post }
  
  if RAILS_ENV == 'development'
    map.connect 'test_install', :controller => 'install', :action => 'test_install'
  end

  map.root :controller => "dashboard"
end