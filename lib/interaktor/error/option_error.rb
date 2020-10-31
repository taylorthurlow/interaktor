class Interaktor::Error::OptionError < Interaktor::Error::Base
  # @return [Hash{Symbol=>Object}]
  attr_reader :options

  # @param interaktor [Class]
  # @param options [Hash{Symbol=>Object}]
  def initialize(interaktor, options)
    super(interaktor)

    @options = options
  end

  def message
    raise NotImplementedError
  end
end
