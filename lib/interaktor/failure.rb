# Error raised during interaction failure. The error stores a copy of the failed
# interaction for debugging purposes.
class Interaktor::Failure < StandardError
  # @return [Interaktor::Interaction] the context of this failure instance
  attr_reader :interaction

  # @param interaction [Interaktor::Interaction] the interaction in which the
  #   error was raised
  def initialize(interaction = nil)
    @interaction = interaction
    super(build_message)
  end

  private

  # Build a human-readable message from the failure attributes, if any were
  # provided to `fail!`. When there are none, returns nil so that
  # StandardError falls back to its default (the exception class name).
  #
  # @return [String, nil]
  def build_message
    attributes = interaction&.failure_object&.attributes
    return if attributes.nil? || attributes.empty?

    attributes
      .map { |name, value| "#{name}: #{value.inspect}" }
      .join(", ")
  end
end
