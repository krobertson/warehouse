module PathAccessibility
  def accessible_by?(user)
    return true  if (user && user.admin?) || repository.public?
    return false if user.nil?
    paths = user.permissions.paths_for(repository)
    paths == :all || paths.any? { |p| path == "#{p}" || path =~ %r{^#{p}/} }
  end
end