class Interaktor::Error::InvalidExceptionHandlerError < Interaktor::Error::Base
  # @return [String]
  def message
    "An exception handler cannot accept a predefined lambda/proc AND a block argument. Remove one."
  end
end
