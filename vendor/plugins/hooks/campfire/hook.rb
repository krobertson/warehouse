$LOAD_PATH << File.join(File.dirname(__FILE__), 'vendor/tinder/lib')

Warehouse::Hooks.define :campfire do
  title "Campfire"
  author "activereload"
  version "1.0"
  homepage 'http://activereload.net'
  notes <<-END_NOTES
    This plugin logs into and speaks in a campfire room for every commit.
    
    This small hook requires a Campfire account, uses Tinder to talk to Campfire, and was adapted
    from code written by Chris Wanstrath.
    
    http://campfirenow.com
    http://tinder.rubyforge.org/
    http://errtheblog.com
  END_NOTES
  
  option :campfire, "Your campfire subdomain"
  option :room, "(optional) Your Campfire room ID."
  option :user, "Email used to log into campfire.  (You should use a dedicated account for this)"
  option :password, "Your campfire password"
  option :url, "A string format for a direct link to a changeset.  ex: 'http://%s.wh.yourdomain.com/changesets/%s'"
  
  permalink do
    options[:url] % [commit.repo[:subdomain], commit.revision.to_s]
  end
  
  init do
    require 'tinder'
  end
  
  run do
    campfire = Tinder::Campfire.new options[:campfire]
    campfire.login options[:user], options[:password]
    room = options[:room] ? Tinder::Room.new(campfire, options[:room]) : campfire.rooms.first
    room.speak "#{repo[:subdomain]}: #{commit.author} committed [#{commit.revision}] #{permalink}"
    room.paste "#{commit.log}\n#{commit.changed}"
  end
end