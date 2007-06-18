module Kernel
  # Require a library with fallback to RubyGems.  Warnings during library
  # loading are silenced to increase signal/noise for application warnings.
  def require_library_or_gem(library_name)
    begin
      require library_name
    rescue LoadError => cannot_require
      # 1. Requiring the module is unsuccessful, maybe it's a gem and nobody required rubygems yet. Try.
      begin
        require 'rubygems'
      rescue LoadError => rubygems_not_installed
        raise cannot_require
      end
      # 2. Rubygems is installed and loaded. Try to load the library again
      begin
        require library_name
      rescue LoadError => gem_not_installed
        raise cannot_require
      end
    end
  end
end

namespace :warehouse do
  task :init do
    require 'config/initializers/svn'
    require 'importer/base'
    config = {}
    YAML.load_file("config/database.yml")[RAILS_ENV].each do |k, v|
      config[k.to_sym] = v
    end
    Importer::MysqlAdapter.create config
  end

  task :post_commit => :sync do
    # eventually add other stuff here, like email
  end

  task :sync => :find_repo do
    @repo.sync_revisions(@num)
  end

  task :clear => :find_repo do
    @repo.clear_revisions!
    puts "All repositories for #{@repo.attributes['name'].inspect} were cleared."
  end

  task :find_repo => :init do
    @num  = (ENV['NUM'] || ENV['N']).to_i
    repo_id = ENV['REPO'].to_i
    @repo = repo_id > 0 ?  Importer::Repository.find_by_id(repo_id) : Importer::Repository.find_first("name = '#{ENV['REPO']}'")
    raise "Please select a repo with REPO=id or REPO=repository_name" if @repo.nil?
  end
end