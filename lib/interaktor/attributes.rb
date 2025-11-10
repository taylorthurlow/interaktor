require "active_model"

module Interaktor
  class Attributes
    include ::ActiveModel::Attributes
    include ::ActiveModel::Serialization
    include ::ActiveModel::Validations

    if defined?(::ActiveModel::Attributes::Normalization)
      include ::ActiveModel::Attributes::Normalization
    end

    DISALLOWED_ATTRIBUTE_NAMES = instance_methods

    def self.check_for_disallowed_attribute_names!
      attribute_names
        .select { |name| DISALLOWED_ATTRIBUTE_NAMES.include?(name.to_sym) }
        .join(", ")
        .tap { |names| raise ArgumentError, "Disallowed attribute name(s): #{names}" if names.present? }
    end
  end
end
