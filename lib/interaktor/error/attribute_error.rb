class Interaktor::Error::AttributeError < Interaktor::Error::Base
  # @return [Array<Symbol>]
  attr_reader :attributes

  # @param interaktor [Class]
  # @param attributes [Array<Symbol>]
  def initialize(interaktor, attributes)
    super(interaktor)

    @attributes = attributes
  end

  # @return [String]
  # @abstract
  def message
    raise NoMethodError
  end
end
