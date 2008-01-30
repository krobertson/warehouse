module Repository::GitMethods
  def clone_url
    # git://githost.com/#{subdomain}.git
  end
  
  def push_url
    # git@githost.com:#{subdomain}.git
  end

  def revisions_to_sync
    @revisions_to_sync ||= begin
      branch_prefix = synced_revision.blank? ? '' : synced_revision.to_s + ".."
      silo.send(:backend).git.rev_list({}, silo.send(:backend).heads.collect { |h| branch_prefix + h.name }).split
    end
  end
  
  def sync_progress
    total = changesets_count + revisions_to_sync.size
    ((changesets_count.to_f / total.to_f) * 100).floor
  end
end