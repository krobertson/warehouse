module PermissionsHelper
  @@permission_options = [['Read access', '0'], ['Read and write access', '1']]

  def path_permissions(permission = nil)
    @path_permission_index = @path_permission_index.nil? ? 0 : @path_permission_index + 1
    access_value = permission ? (permission.full_access ? '1' : '0') : (params[:permission][:paths][@path_permission_index][:full_access] rescue nil)
    path_value   = permission ? permission.path : (params[:permission][:paths][@path_permission_index][:path] rescue nil)
    %(<dd id="path"><select name="permission[paths][][full_access]" class="sel">) +
      options_for_select(@@permission_options, access_value) + 
      %(</select> to ) + 
      text_field_tag("permission_paths_#{@path_permission_index}_path", path_value, :name => "permission[paths][][path]", :class => 'path') + 
      (permission ? hidden_field_tag("permission_paths_#{@path_permission_index}_id", permission.id, :name => "permission[paths][][id]") : '') +
      %( <a href="#add" class="addpath">(+)</a></dd>)
  end
end
