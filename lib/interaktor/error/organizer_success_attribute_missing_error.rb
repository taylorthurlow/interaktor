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
    <<~MESSAGE.strip.tr("\n", " ")
      A #{interaktor} organizer requires a '#{attribute}' success attribute,
      but none of the success attributes provided by any of the organized
      interaktors list it.
    MESSAGE
  end
end
