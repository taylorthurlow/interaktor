class Interaktor::Error::AttributeSchemaValidationError < Interaktor::Error::Base
  # @return [Hash{Symbol=>Array<String>}]
  attr_reader :validation_errors

  # @param interaktor [Class]
  # @param validation_errors [Hash{Symbol=>Array<String>}]
  def initialize(interaktor, validation_errors)
    super(interaktor)

    @validation_errors = validation_errors
  end

  # @return [String]
  # @abstract
  def message
    "Interaktor attribute schema failed validation:\n  #{error_list}"
  end

  private

  # @return [String]
  def error_list
    result = ""

    validation_errors.each do |attribute, errors|
      result << "#{attribute}:\n"

      errors.each do |error|
        result << "    - #{error}"
      end
    end

    result
  end
end
