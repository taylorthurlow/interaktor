class Interaktor::Error::UnknownAttributeError < Interaktor::Error::AttributeError
  # @return [Symbol]
  attr_reader :attribute

  # @param interaktor [Class]
  # @param attribute [Symbol]
  def initialize(interaktor, attribute)
    super(interaktor, [attribute])

    @attribute = attribute
  end

  def message
    "Unknown attribute '#{attribute}'"
  end
end
