class Interaktor::Error::OrganizerMissingPassedAttributeError < Interaktor::Error::AttributeError
  # @return [Symbol]
  attr_reader :attribute

  # @return [Class]
  attr_reader :previous_interaktor

  # @return [Class]
  attr_reader :next_interaktor

  # @param previous_interaktor [Class]
  # @param next_interaktor [Class]
  # @param attribute [Symbol]
  def initialize(previous_interaktor, next_interaktor, attribute)
    super(previous_interaktor, [attribute])

    @previous_interaktor = previous_interaktor
    @next_interaktor = next_interaktor
    @attribute = attribute
  end

  def message
    <<~MESSAGE.strip.gsub(/\s+/, " ")
      An organized #{next_interaktor} interaktor requires a '#{attribute}'
      input attribute, but the output of the #{previous_interaktor} interaktor
      before it does not list it as a success attribute.
    MESSAGE
  end
end
