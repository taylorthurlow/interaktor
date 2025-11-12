class Interaktor::Error::UnknownAttributeError < Interaktor::Error::AttributeError
  # @return [String]
  attr_reader :attribute

  # @param interaktor [Class]
  # @param attribute [Symbol, String]
  def initialize(interaktor, attribute)
    super(interaktor, [attribute.to_s])

    @attribute = attribute.to_s
  end

  def message
    "Unknown attribute '#{attribute}'"
  end
end
