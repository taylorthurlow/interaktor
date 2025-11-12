class Interaktor::Error::OrganizerMissingPassedAttributeError < Interaktor::Error::AttributeError
  # @return [String]
  attr_reader :attribute

  # @param next_interaktor [Class]
  # @param attribute [Symbol, String]
  def initialize(interaktor, attribute)
    super(interaktor, [attribute.to_s])

    @attribute = attribute.to_s
  end

  def message
    <<~MESSAGE.strip.tr("\n", " ")
      An organized #{interaktor} interaktor defines a '#{attribute}' input
      attribute, but none of the interaktors that come before it in the
      organizer list it as a success attribute, and the organizer does not
      define it as an input attribute.
    MESSAGE
  end
end
