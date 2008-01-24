##
## $Rev: 77 $
## $Release: 2.4.1 $
## copyright(c) 2006-2007 kuwata-lab.com all rights reserved.
##

module Erubis


  ##
  ## base error class
  ##
  class ErubisError < StandardError
  end


  ##
  ## raised when method or function is not supported
  ##
  class NotSupportedError < ErubisError
  end


end
