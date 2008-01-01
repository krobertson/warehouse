require 'vlad'

namespace :vlad do
  ##
  # Monit

  set :monit_group,   'mongrel'
  set :monit_command, 'monit'

  desc "Prepares application servers for deployment.".cleanup

  remote_task :setup_app, :roles => [:app, :slice] do
    dirs = [deploy_to, releases_path, scm_path, shared_path]
    dirs += %w(system log pids).map { |d| File.join(shared_path, d) }
    run "umask 02 && mkdir -p #{dirs.join(' ')}"
    # TODO: I have no idea how to setup monit
  end

  def monit(cmd) # :nodoc:
    "#{monit} #{cmd} -g #{monit_group}"
  end

  desc "Restart the app servers"

  remote_task :start_app, :roles => :app do
    run monit("restart all")
  end

  desc "Stop the app servers"

  remote_task :stop_app, :roles => :app do
    run monit("stop all")
  end
end
