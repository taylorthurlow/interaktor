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
    # Fails if an organized interaktor fails.
    #
    # @raises [Interaktor::Failure] if an organized interaktor fails
    #
    # @return [void]
    def call
      # An organizer that declares failure attributes must build them from the
      # failed interaction of an organized interaktor, so it must define
      # `failure_attributes_from`. One that declares none has nothing to build.
      declares_failure_attributes = !!defined?(self.class::FailureAttributesModel)
      if declares_failure_attributes != respond_to?(:failure_attributes_from, true)
        raise Interaktor::Error::InvalidOrganizerFailureDefinitionError.new(self.class)
      end

      latest_interaction = nil

      self.class.organized.each do |interaktor|
        # `.call` raises the failure of any other interaktor that the organized
        # interaktor calls, so a failed interaction here is always its own.
        interaction = interaktor.call(latest_interaction || @interaction)

        if interaction.failure?
          if declares_failure_attributes
            fail!(failure_attributes_from(interaction) || {})
          else
            fail!
          end
        end

        latest_interaction = interaction
      end

      if defined?(self.class::SuccessAttributesModel)
        @interaction.success!(
          latest_interaction
            .success_object
            &.attributes
            &.slice(*self.class::SuccessAttributesModel.attribute_names) || {}
        )
      end
    end
  end
end
