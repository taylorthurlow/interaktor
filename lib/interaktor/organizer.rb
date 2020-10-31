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
      self.class.organized.each do |interaktor|
        # Take the context that is being passed to each interaktor and remove
        # any attributes from it that are not required by the interactor.
        @context.to_h
                .keys
                .reject { |attr| interaktor.input_attributes.include?(attr) }
                .each { |attr| @context.delete_field(attr) }

        catch(:early_return) { interaktor.call!(@context) }
      end
    end
  end
end
