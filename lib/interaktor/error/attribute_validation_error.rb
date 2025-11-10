class Interaktor::Error::AttributeValidationError < Interaktor::Error::Base
  attr_reader :model

  # @param model [Object]
  def initialize(interaktor, model)
    super(interaktor)

    @model = model
  end

  # @return [Hash{Symbol=>Array<String>}]
  def validation_errors
    model.errors.messages
  end

  # @return [String]
  def message
    "Interaktor attributes failed validation:\n  #{model.errors.full_messages.join("\n  ")}"
  end
end
