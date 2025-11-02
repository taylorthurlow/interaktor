class Interaktor::Error::InvalidMethodForStateError < Interaktor::Error::Base
  attr_reader :message

  # @param interaktor [Class]
  # @param method [Symbol]
  def initialize(interaktor, message)
    super(interaktor)
    @message = message
  end
end
