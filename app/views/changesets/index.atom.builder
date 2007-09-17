atom_feed(:url => controller.action_name == 'index' ? formatted_changesets_url(:atom) : formatted_public_changesets_url(:atom)) do |feed|
  if current_repository
    feed.title("Changesets for #{current_repository.name}")
  else
    feed.title("#{'Public ' if controller.action_name == 'public'}Changesets")
  end
  feed.updated((@changesets.first ? @changesets.first.changed_at : Time.now.utc).xmlschema)

  render :partial => 'changesets', :object => @changesets, :locals => {'feed' => feed}
end