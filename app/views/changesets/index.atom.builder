atom_feed(:schema_date => File.ctime(File.join(RAILS_ROOT, 'config', 'initializers', 'warehouse.rb')),
	:url => hosted_url(controller.action_name == 'index' ? :formatted_root_changesets : :formatted_root_public_changesets, :atom)) do |feed|
  if current_repository
    feed.title("Changesets for #{current_repository.name}")
  else
    feed.title("#{'Public ' if controller.action_name == 'public'}Changesets")
  end
  feed.updated((@changesets.first ? @changesets.first.changed_at : Time.now.utc))

  render :partial => 'changesets', :object => @changesets, :locals => {'feed' => feed}
end