module PermissionMethods
  def permission_changesets_count
    read_attribute(:permission_changesets_count).to_i
  end
  
  def last_changed_at
    l = read_attribute :last_changed_at
    l ? Time.parse(l) : nil
  end

  def permission_admin?
    permission_admin && User.columns_hash['admin'].type_cast(permission_admin)
  end
end