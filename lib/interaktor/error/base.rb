class Interaktor::Error::Base < StandardError
  # @return [Class]
  attr_reader :interaktor

  # @param interaktor [Class]
  def initialize(interaktor)
    @interaktor = interaktor
  end
end
