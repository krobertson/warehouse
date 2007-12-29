atom_feed(:url => hosted_url(:history, :paths => params[:paths])) do |feed|
  feed.title("Changesets for #{current_repository.name} in #{@node.path}")
  feed.updated((@changesets.first ? @changesets.first.changed_at : Time.now.utc).xmlschema)

  render :partial => 'changesets/changesets', :object => @changesets, :locals => {'feed' => feed}
end