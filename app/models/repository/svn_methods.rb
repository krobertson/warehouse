module Repository::SvnMethods
  def revisions_to_sync
    @revisions_to_sync ||= begin
      ((synced_revision.to_i + 1)..latest_revision.to_i).to_a
    end
  end

  def sync_progress
    ((synced_revision.to_f / latest_revision.to_f) * 100).floor
  end
end