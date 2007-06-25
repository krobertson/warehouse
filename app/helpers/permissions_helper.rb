module PermissionsHelper
  @@permission_options = [['Read access', '0'], ['Read and write access', '1']]

  def show_new_permission_form?
    admin? && (!@invitees.blank? || !@members.keys.include?(nil))
  end

  def path_permissions(permission = nil)
    @path_permission_index = @path_permission_index.nil? ? 0 : @path_permission_index + 1
    access_value = permission ? (permission.full_access ? '1' : '0') : (params[:permission][:paths][@path_permission_index][:full_access] rescue nil)
    path_value   = permission ? permission.path : (params[:permission][:paths][@path_permission_index][:path] rescue nil)
    %(<p#{%( id="#{dom_id permission}") if permission}><select name="permission[paths][#{@path_permission_index}][full_access]" class="sel">) +
      options_for_select(@@permission_options, access_value) + 
      %(</select> to ) + 
      text_field_tag("permission_paths_#{@path_permission_index}_path", path_value, :name => "permission[paths][#{@path_permission_index}][path]", :class => 'path') + 
      (permission ? hidden_field_tag("permission_paths_#{@path_permission_index}_id", permission.id, :name => "permission[paths][#{@path_permission_index}][id]") : '') +
      %( <a href="#add" class="addpath"><img src="/images/app/icons/plus-small.png" /></a> <a class="delpath" href="#" title="Delete"><img src="/images/app/icons/delete.png" /></a></p>)
  end
  
  def invitee_options_for(invitees)
    options = invitees.collect { |u| [u.name, u.id] }
    options << ['Anonymous', ''] unless @members.keys.include?(nil)
    options
  end
end
