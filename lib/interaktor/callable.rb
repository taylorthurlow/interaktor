module Interaktor::Callable
  # When the module is included in a class, add the relevant class methods to
  # that class.
  #
  # @param base [Class] the class which is including the module
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def input(&block)
      raise "Input block already defined" if defined?(self::InputAttributesModel)

      # Define self::InputAttributesModel
      Class.new(Interaktor::Attributes, &block).tap do |klass|
        klass.define_singleton_method(:inspect) { name.to_s }
        klass.define_singleton_method(:to_s) { inspect }

        const_set(:InputAttributesModel, klass)

        klass.check_for_disallowed_attribute_names!

        klass.attribute_names.each { |name| define_attribute_reader(name) }
      end
    end

    def failure(&block)
      raise "Failure block already defined" if defined?(self::FailureAttributesModel)

      # Define self::FailureAttributesModel
      Class.new(Interaktor::Attributes, &block).tap do |klass|
        klass.define_singleton_method(:inspect) { name.to_s }
        klass.define_singleton_method(:to_s) { inspect }

        const_set(:FailureAttributesModel, klass)

        klass.check_for_disallowed_attribute_names!
      end
    end

    def success(&block)
      raise "Success block already defined" if defined?(self::SuccessAttributesModel)

      # Define self::SuccessAttributesModel
      Class.new(Interaktor::Attributes, &block).tap do |klass|
        klass.define_singleton_method(:inspect) { name.to_s }
        klass.define_singleton_method(:to_s) { inspect }

        const_set(:SuccessAttributesModel, klass)

        klass.check_for_disallowed_attribute_names!

        klass.attribute_names.each { |name| define_attribute_reader(name) }
      end
    end

    # Invoke an Interaktor. This is the primary public API method to an
    # interaktor. Interaktor failures will not raise an exception.
    #
    # @param args [Hash, Interaktor::Interaction]
    #
    # @return [Interaktor::Interaction]
    def call(args = {})
      execute(args, raise_exception: false)
    end

    # Invoke an Interaktor. This method behaves identically to `#call`, but if
    # the interaktor fails, `Interaktor::Failure` is raised.
    #
    # @param args [Hash, Interaktor::Interaction]
    #
    # @raises [Interaktor::Failure]
    #
    # @return [Interaktor::Interaction]
    def call!(args = {})
      execute(args, raise_exception: true)
    end

    private

    # Define a method on the interaktor that returns the value of an input or
    # success attribute.
    #
    # @param name [String]
    #
    # @return [void]
    def define_attribute_reader(name)
      # Rejects the name of a method that the gem defines on every interaktor,
      # because the attribute method would replace it.
      gem_method = [Interaktor, Interaktor::Hooks].any? do |mod|
        mod.method_defined?(name) || mod.private_method_defined?(name)
      end
      raise ArgumentError, "Disallowed attribute name(s): #{name}" if gem_method

      self::AttributeMethods.define_method(name) do
        # Reads the attribute objects directly, because the interaction stops
        # returning input attributes once it has finished. A success attribute
        # replaces an input attribute of the same name once the interaktor has
        # succeeded.
        [@interaction.success_object, @interaction.input_object]
          .compact
          .find { |attributes| attributes.attribute_names.include?(name) }
          &.send(name)
      end
    end

    # The main execution method triggered by the public `#call` or `#call!`
    # methods.
    #
    # @param args [Hash, Interaktor::Interaction]
    # @param raise_exception [Boolean] whether or not to raise exception on
    #   failure
    #
    # @raises [Interaktor::Failure]
    #
    # @return [Interaktor::Interaction]
    def execute(args, raise_exception:)
      interaction = case args
      when Hash, Interaktor::Interaction
        new(args)
          .tap(&(raise_exception ? :run! : :run))
          .instance_variable_get(:@interaction)
      else
        raise ArgumentError,
          "Expected a hash argument when calling the interaktor, got a #{args.class} instead."
      end

      if interaction.success? &&
          !interaction.early_return? &&
          defined?(self::SuccessAttributesModel)
        raise Interaktor::Error::MissingExplicitSuccessError.new(self)
      end

      interaction
    end
  end
end
