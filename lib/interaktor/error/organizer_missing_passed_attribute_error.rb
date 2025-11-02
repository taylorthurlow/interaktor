class Interaktor::Error::OrganizerMissingPassedAttributeError < Interaktor::Error::AttributeError
  # @return [Symbol]
  attr_reader :attribute

  # @param next_interaktor [Class]
  # @param attribute [Symbol]
  def initialize(interaktor, attribute)
    super(interaktor, [attribute])

    @attribute = attribute
  end

  def message
    <<~MESSAGE.strip.tr("\n", " ")
      An organized #{interaktor} interaktor requires a '#{attribute}' input
      attribute, but none of the interaktors that come before it in the
      organizer list it as a success attribute, and the organizer does not list
      it as a required attribute.
    MESSAGE
  end
end
