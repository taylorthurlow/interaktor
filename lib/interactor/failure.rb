# Error raised during Interactor::Context failure. The error stores a copy of
# the failed context for debugging purposes.
class Interactor::Failure < StandardError
  # @return [Interactor::Context] the context of this failure instance
  attr_reader :context

  # @param context [Interactor::Context] the context in which the error was
  #   raised
  def initialize(context = nil)
    @context = context
    super
  end
end
