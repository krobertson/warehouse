module PermissionsHelper
  @@permission_options = [['Read access', false], ['Read and write access', true]]

  def path_permissions(permission = nil)
    @path_permission_index = @path_permission_index.nil? ? 0 : @path_permission_index + 1
    path_value = permission ? permission.path : (params[:permission][:paths][@path_permission_index][:path] rescue nil)
    %(<dd><select name="permission[paths][][full_access]">) +
      options_for_select(@@permission_options, permission ? permission.full_access : false) + 
      %(</select> to ) + 
      text_field_tag("permission_paths_#{@path_permission_index}_path", path_value, :name => "permissions[paths][][path]") + 
      (permission ? hidden_field_tag("permission_paths_#{@path_permission_index}_id", permission.id, :name => "permissions[paths][][id]") : '') +
      %( <a href="#" class="addpath">(+)</a></dd>)
  end
end
