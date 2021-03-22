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
      check_attribute_flow_valid

      self.class.organized.each do |interaktor|
        catch(:early_return) { interaktor.call!(@context) }
      end
    end

    private

    # @return [void]
    def check_attribute_flow_valid
      interaktors = self.class.organized

      # @type [Array<Symbol>]
      success_attributes_so_far = []

      success_attributes_so_far += self.class.required_input_attributes

      # @param interaktor [Class]
      interaktors.each do |interaktor|
        interaktor.required_input_attributes.each do |required_attr|
          unless success_attributes_so_far.include?(required_attr)
            raise Interaktor::Error::OrganizerMissingPassedAttributeError.new(interaktor, required_attr)
          end
        end

        success_attributes_so_far += interaktor.success_attributes

        next unless interaktor == interaktors.last

        self.class.success_attributes.each do |success_attr|
          unless success_attributes_so_far.include?(success_attr)
            raise Interaktor::Error::OrganizerSuccessAttributeMissingError.new(interaktor, success_attr)
          end
        end
      end
    end
  end
end
