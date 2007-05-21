module ChangesetsHelper
  def diff_for(change)    
    raw_diff = change.unified_diff
    diff_line_regex = %r{@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@}
    lines = raw_diff.split("\n")
        
    original_revision_num = lines[0].scan(%r{(\d+)}).flatten.first
    current_revision_num = lines[1].scan(%r{(\d+)}).flatten.first
    
    original_revision = link_to_node(original_revision_num, change.path, original_revision)
    current_revision  = link_to_node(current_revision_num, change.path, current_revision)
    
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
      code = content_tag('td', "<pre>#{line[2]}</pre>", :class => 'code' + (line[3] ? " #{line[3]}" : ''))
  
      table_rows << content_tag('tr', pnum + cnum + code)
    end
    
    %(
    <table class="diff" cellspacing="0" cellpadding="0">
      <thead>
        <tr class="controls">
          <td colspan="3">
            <div class="control-">
              #{link_to_node change.path, change.node, current_revision_num}
              [#{link_to 'diff', formatted_changeset_change_path(@changeset, change, :diff)}]
            </div>
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
    )
  end
end
