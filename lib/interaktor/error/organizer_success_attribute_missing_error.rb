class Interaktor::Error::OrganizerSuccessAttributeMissingError < Interaktor::Error::AttributeError
  # @return [String]
  attr_reader :attribute

  # @param interaktor [Class]
  # @param attribute [Symbol, String]
  def initialize(interaktor, attribute)
    super(interaktor, [attribute.to_s])

    @attribute = attribute.to_s
  end

  def message
    <<~MESSAGE.strip.tr("\n", " ")
      A #{interaktor} organizer requires a '#{attribute}' success attribute,
      but none of the success attributes provided by any of the organized
      interaktors list it.
    MESSAGE
  end
end
