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
        interaktor.call!(context)
      end
    end

    private

    # A list of attributes required to invoke the organized Interaktors.
    # Obtained by compiling a list of all required attributes of all organized
    # interaktors. Duplicates are removed.
    #
    # @return [Array<Symbol>]
    def required_attributes
      self.class.organized.map(&:required_attributes).flatten.uniq
    end

    # A list of optional attributes allowed to be included when invoking the
    # organized Interaktors. Obtained by compiling a list of all optional
    # attributes of all organized interaktors. Duplicates are removed.
    #
    # @return [Array<Symbol>]
    def optional_attributes
      self.class.organized.map(&:optional_attributes).flatten.uniq
    end
  end
end
