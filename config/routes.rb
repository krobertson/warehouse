ActionController::Routing::Routes.draw do |map|
  map.resources :changesets, :has_many => :changes
  map.with_options :controller => 'browser', :action => 'index' do |b|
    b.rev_browser 'browser/:rev/*paths', :rev => /r\d+/
    b.browser 'browser/*paths'
    b.text    'text/*paths', :action => 'text'
    b.raw     'raw/*paths',  :action => 'raw'
  end
  map.history 'history/*paths', :controller => 'history', :action => 'index'
  map.root :controller => "dashboard"
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end