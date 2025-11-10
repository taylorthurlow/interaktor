module Interaktor::Organizer
  # When the Interaktor::Organizer module is included in a class, add the
  # relevant class methods and hooks to that class.
  #
  # @param base [Class] the class which is including the Interaktor::Organizer
  #   module
  def self.included(base)
    base.class_eval do
      include Interaktor

      extend ClassMethods
      include InstanceMethods
    end
  end

  module ClassMethods
    # Declare Interaktors to be invoked as part of the Interaktor::Organizer's
    # invocation. These interaktors are invoked in the order in which they are
    # declared.
    #
    # @param interaktors [Interaktor, Array<Interaktor>]
    #
    # @return [void]
    def organize(*interaktors)
      organized.concat(interaktors.flatten)
    end

    # An array of declared Interaktors to be invoked.
    #
    # @return [Array<Interaktor>]
    def organized
      @organized ||= []
    end
  end

  module InstanceMethods
    # Invoke the organized Interaktors. An Interaktor::Organizer is expected
    # NOT to define its own `#call` in favor of this default implementation.
    #
    # @return [void]
    def call
      # TODO: Not sure how to achieve this with ActiveModel not making it easy
      # to determine if a given attribute can be nil or not (is it required or
      # not?) - easy to do at the time of interaction start, but not in advance
      # like this
      # check_attribute_flow_valid

      latest_interaction = nil

      self.class.organized.each do |interaktor|
        catch(:early_return) do
          latest_interaction = interaktor.call!(latest_interaction || @interaction)
        end
      end

      if defined?(self.class::SuccessAttributesModel)
        @interaction.success!(
          latest_interaction
            .success_object
            &.attributes
            &.slice(*self.class::SuccessAttributesModel.attribute_names)
            &.transform_keys(&:to_sym) || {}
        )
      end
    end
  end
end
