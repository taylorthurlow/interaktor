class Interaktor::Error::OrganizerSuccessAttributeMissingError < Interaktor::Error::AttributeError
  # @return [Symbol]
  attr_reader :attribute

  # @param interaktor [Class]
  # @param attribute [Symbol]
  def initialize(interaktor, attribute)
    super(interaktor, [attribute])

    @attribute = attribute
  end

  def message
    <<~MESSAGE.strip.gsub(/\s+/, " ")
      #{interaktor} organizer requires a '#{attribute}' success attribute,
      but the output of the #{interaktor} interaktor at the end of the
      organized list does not list it as a success attribute.
    MESSAGE
  end
end
