# Parts were adapted from Retrospectiva
# http://retrospectiva.org/browse/trunk/app/helpers/changesets_helper.rb?rev=141
module ChangesetsHelper
  def link_to_diff(text, revision, path, options = {})
    link_to text, hosted_url(:diff, "r#{revision}", path.split("/")), options
  end

  def unified_diff_for(node, options = {})
    old_rev = find_revision_for(node, options[:old_rev])

    old_rev, new_rev, raw_diff = node.unified_diff_with(old_rev)
    if raw_diff.empty?
      return nil
    end
    
    unified = Diff::Display::Unified.new(raw_diff)
    
    old_link, new_link = nil, nil
    if controller.action_name == 'diff'
      old_link = link_to_diff(truncate(old_rev, 7, ''), old_rev, node.path)
      new_link = link_to_diff(truncate(new_rev, 7, ''),  new_rev,  node.path)
    else
      old_link = link_to_node(truncate(old_rev, 7, ''), node, old_rev)
      new_link = link_to_node(truncate(new_rev, 7, ''),  node, new_rev)
    end
    
    %(
    <div class="diff-table">
    <table class="diff" cellspacing="0" cellpadding="0" id="#{options[:id]}">
      <thead>
        <tr class="controls">
          <td colspan="3">
            <div class="control">#{yield old_rev, new_rev if block_given?}</div>
          </td>
        </tr>
        <tr>
          <th class="csnum">#{old_link}</th>
          <th class="csnum">#{new_link}</th>
          <th>&nbsp;</th>
        </tr>
      </thead>
      <tbody>
      #{unified.render(Warehouse::DiffRenderer.new)}
      </tbody>
    </table>
    </div>
    )
  end
  
  # wraps a change's diff and specifies a header.
  def diff_for(change)
    unified_diff_for change.node, :id => dom_id(change) do |original_revision_num, current_revision_num|
      %(
      <span class="csfile">#{link_to_node change.path, change.node, current_revision_num}</span>
      #{link_to 'diff', hosted_url(:formatted_changeset_change, @changeset, change, :diff), :class => 'csdiff'}
      )
    end
  end
  
  def find_revision_for(node, other)
    return other if other.nil? || other.is_a?(Silo::Node)
    if other.is_a?(Date)
      changeset = current_repository.changesets.find_by_date_for_path(other, node.path)
      return changeset ? changeset.revision : nil
    end
    
    node.repository.revision?(other)     || 
      relative_revision_for(node, other) ||
      raise(Silo::Node::Error, "Invalid Revision: #{other.inspect}")
  end
  
  def relative_revision_for(node, other)
    changeset = \
      case other
        when /^head/i then current_repository.changesets.find(:first)
        when /^next/i then current_repository.changesets.find_after(changeset_paths, @changeset)
        when /^prev/i then current_repository.changesets.find_before(changeset_paths, @changeset)
      end
    changeset ? changeset.revision : nil
  end
end
