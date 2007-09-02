require File.dirname(__FILE__) + '/../../../test/test_helper'
def load_hook(hook)
  require File.join(File.dirname(__FILE__), hook.to_s, 'hook')
end