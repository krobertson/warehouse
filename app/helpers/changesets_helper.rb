# Parts were adapted from Retrospectiva
# http://retrospectiva.org/browse/trunk/app/helpers/changesets_helper.rb?rev=141
module ChangesetsHelper
  def link_to_diff(text, revision, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    link_to text, hosted_url(:diff, "r#{revision}", args.first.split("/")), options
  end

  def unified_diff_for(node, options = {})
    options[:old_rev] ||= node.previous_root
    options[:new_rev] ||= node.root
    options[:path]    ||= node.path

    raw_diff = node.unified_diff_for options[:old_rev], options[:new_rev], options[:path]
    if raw_diff.empty?
      return nil
    end
    diff_line_regex = %r{@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@}
    lines = raw_diff.split("\n")
        
    original_revision_num = lines[0].scan(%r{(\d+)}).flatten.first
    current_revision_num = lines[1].scan(%r{(\d+)}).flatten.first
    original_revision = nil
    current_revision  = nil
    if controller.action_name == 'diff'
      original_revision = link_to_diff(original_revision_num, original_revision_num, options[:path])
      current_revision  = link_to_diff(current_revision_num,  current_revision_num,  options[:path])
    else
      original_revision = link_to_node(original_revision_num, options[:path], original_revision_num)
      current_revision  = link_to_node(current_revision_num, options[:path], current_revision_num)
    end
    
    th_pnum = content_tag('th', original_revision, :class => 'csnum')
    th_cnum = content_tag('th', current_revision, :class => 'csnum')  
    table_rows = []  
        
    lines = lines[2..lines.length].collect{ |line| h(line) }
  
    ln = [0, 0]   # line counter
    lines = lines.collect do |line|      
      if line.starts_with?('-')        
        [ln[0] += 1, '', ' ' + line[1..line.length], 'delete']
      elsif line.starts_with?('+')
        ['', ln[1] += 1, ' ' + line[1..line.length], 'insert']
      elsif line_defs = line.match(diff_line_regex)
              ln[0] = line_defs[1].to_i - 1
              ln[1] = line_defs[3].to_i - 1
        ['---', '---', '', nil]
      elsif line.match('\ No newline at end of file')
        nil
      else
        [ln[0] += 1, ln[1] += 1, line, nil]
      end     
    end.compact
    
    lines[1..lines.length].collect do |line|
      pnum = content_tag('td', line[0], :class => 'ln')
      cnum = content_tag('td', line[1], :class => 'ln')    
      code = content_tag('td', line[2].gsub(/ /, '&nbsp;'), :class => 'code' + (line[3] ? " #{line[3]}" : ''))
      table_rows << content_tag('tr', pnum + cnum + code)
    end
    
    %(
    <div class="diff-table">
    <table class="diff" cellspacing="0" cellpadding="0" id="#{options[:id]}">
      <thead>
        <tr class="controls">
          <td colspan="3">
            <div class="control">#{yield original_revision_num, current_revision_num if block_given?}</div>
          </td>
        </tr>
        <tr>
          #{th_pnum}
          #{th_cnum}
          <th>&nbsp;</th>
        </tr>
      </thead>
      #{table_rows.join("\n")}
    </table>
    </div>
    )
  end
  
  def diff_for(change)
    unified_diff_for change.node, :id => dom_id(change) do |original_revision_num, current_revision_num|
      %(
      <span class="csfile">#{link_to_node change.path, change.node, current_revision_num}</span>
      #{link_to 'diff', hosted_url(:formatted_changeset_change, @changeset, change, :diff), :class => 'csdiff'}
      )
    end
  end
end
