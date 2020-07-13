module Interactor::Organizer
  # When the Interactor::Organizer module is included in a class, add the
  # relevant class methods and hooks to that class.
  #
  # @param base [Class] the class which is including the Interactor::Organizer
  #   module
  def self.included(base)
    base.class_eval do
      include Interactor

      extend ClassMethods
      include InstanceMethods
    end
  end

  module ClassMethods
    # Declare Interactors to be invoked as part of the Interactor::Organizer's
    # invocation. These interactors are invoked in the order in which they are
    # declared.
    #
    # @param interactors [Interactor, Array<Interactor>]
    #
    # @return [void]
    def organize(*interactors)
      organized.concat(interactors.flatten)
    end

    # An array of declared Interactors to be invoked.
    #
    # @return [Array<Interactor>]
    def organized
      @organized ||= []
    end
  end

  module InstanceMethods
    # Invoke the organized Interactors. An Interactor::Organizer is expected
    # NOT to define its own `#call` in favor of this default implementation.
    #
    # @return [void]
    def call
      self.class.organized.each do |interactor|
        interactor.call!(@context)
      end
    end

    private

    # A list of attributes required to invoke the organized Interactors.
    # Obtained by compiling a list of all required attributes of all organized
    # interactors. Duplicates are removed.
    #
    # @return [Array<Symbol>]
    def required_attributes
      self.class.organized.map(&:required_attributes).flatten.uniq
    end

    # A list of optional attributes allowed to be included when invoking the
    # organized Interactors. Obtained by compiling a list of all optional
    # attributes of all organized interactors. Duplicates are removed.
    #
    # @return [Array<Symbol>]
    def optional_attributes
      self.class.organized.map(&:optional_attributes).flatten.uniq
    end
  end
end
