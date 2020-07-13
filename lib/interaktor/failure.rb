# Error raised during Interaktor::Context failure. The error stores a copy of
# the failed context for debugging purposes.
class Interaktor::Failure < StandardError
  # @return [Interaktor::Context] the context of this failure instance
  attr_reader :context

  # @param context [Interaktor::Context] the context in which the error was
  #   raised
  def initialize(context = nil)
    @context = context
    super
  end
end
