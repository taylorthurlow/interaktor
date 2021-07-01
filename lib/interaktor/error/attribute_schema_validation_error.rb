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
      result << error_entry(attribute, errors)
    end

    result
  end

  def error_entry(key, value, depth = 0)
    result = " " * depth * 2

    case value
    when Hash
      result << "#{key}:\n"
      value.each do |sub_key, sub_value|
        result << "  "
        result << error_entry(sub_key, sub_value, depth + 1)
      end
    when Array
      result << "#{key}:\n"
      value.each do |error_message|
        result << "  "
        result << error_entry(nil, error_message, depth + 1)
      end
    else
      result << "- #{value}\n"
    end

    result
  end
end
