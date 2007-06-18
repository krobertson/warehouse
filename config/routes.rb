ActionController::Routing::Routes.draw do |map|
  map.resources :repositories, :bookmarks
  map.resources :permissions, :collection => { :anon => :any }
  map.resources :users, :has_one => [:avatar, :permissions]
  map.resources :changesets, :has_many => :changes
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

  map.history 'history/*paths', :controller => 'history'
  map.admin   'admin',          :controller => 'repositories'

  map.install 'install', :controller => 'install', :action => 'index',   :conditions => { :method => :get  }
  map.connect 'install', :controller => 'install', :action => 'install', :conditions => { :method => :post }

  map.root :controller => "dashboard"
end