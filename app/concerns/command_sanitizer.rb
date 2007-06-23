module CommandSanitizer
  # Replaces :args from objects in the args hash.
  # 
  #   This replaces the given :bar with user.bar
  #     sanitize_command("foo :bar", user => ['bar'])
  def sanitize_command(cmd, objects = {})
    # build hash index of :key => obj
    args = objects.inject({}) do |memo, (obj, key)|
      key.to_a.each { |key| memo.update key => obj }
      memo
    end
    
    cmd.gsub /:\w+/ do |arg|
      arg = arg[1..-1]
      args[arg] ? args[arg].send(arg).to_s : ''
    end.strip
  end
  
  def execute_command(cmd, objects = {})
    sanitized = sanitize_command(cmd, objects)
    result = []
    logger.debug "executing: #{cmd}"
    Open3.popen3 sanitized do |stdin, stdout, stderr|
      result << stdout.read.to_s.strip
      result << stderr.read.to_s.strip
    end
    result
  end
end