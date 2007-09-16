class RepositorySweeper < ActionController::Caching::Sweeper
  observe Repository
  
  def after_save(repository)
    CacheKey.sweep_cache(controller.request, repository) if controller
  end
  
  alias after_destroy after_save
end