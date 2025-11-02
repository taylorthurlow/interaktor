# Error raised during interaction failure. The error stores a copy of the failed
# interaction for debugging purposes.
class Interaktor::Failure < StandardError
  # @return [Interaktor::Interaction] the context of this failure instance
  attr_reader :interaction

  # @param interaction [Interaktor::Interaction] the interaction in which the
  #   error was raised
  def initialize(interaction = nil)
    @interaction = interaction
    super
  end
end
