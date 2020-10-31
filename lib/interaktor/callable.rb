module Interaktor::Callable
  # When the module is included in a class, add the relevant class methods to
  # that class.
  #
  # @param base [Class] the class which is including the module
  def self.included(base)
    base.class_eval { extend ClassMethods }
  end

  module ClassMethods
    # The list of attributes which are required to be passed in when calling
    # the interaktor.
    #
    # @return [Array<Symbol>]
    def required_attributes
      @required_attributes ||= []
    end

    # The list of attributes which are NOT required to be passed in when
    # calling the interaktor.
    #
    # @return [Array<Symbol>]
    def optional_attributes
      @optional_attributes ||= []
    end

    # A list of optional attributes and their default values.
    #
    # @return [Array<Symbol>]
    def optional_defaults
      @optional_defaults ||= {}
    end

    # A list of attributes which could be passed when calling the interaktor.
    #
    # @return [Array<Symbol>]
    def input_attributes
      required_attributes + optional_attributes
    end

    # The list of attributes which are required to be passed in when calling
    # `#fail!` from within the interaktor.
    #
    # @return [Array<Symbol>]
    def failure_attributes
      @failure_attributes ||= []
    end

    # The list of attributes which are required to be passed in when calling
    # `#fail!` from within the interaktor.
    #
    # @return [Array<Symbol>]
    def success_attributes
      @success_attributes ||= []
    end

    # A DSL method for documenting required interaktor attributes.
    #
    # @param attributes [Symbol, Array<Symbol>] the list of attribute names
    # @param options [Hash]
    #
    # @return [void]
    def required(*attributes, **options)
      required_attributes.concat attributes

      attributes.each do |attribute|
        # Define getter
        define_method(attribute) { @context.send(attribute) }

        # Define setter
        define_method("#{attribute}=".to_sym) do |value|
          @context.send("#{attribute}=".to_sym, value)
        end

        raise "Unknown option(s): #{options.keys.join(", ")}" if options.any?
      end
    end

    # A DSL method for documenting optional interaktor attributes.
    #
    # @param attributes [Symbol, Array<Symbol>] the list of attribute names
    # @param options [Hash]
    #
    # @return [void]
    def optional(*attributes, **options)
      optional_attributes.concat attributes

      attributes.each do |attribute|
        # Define getter
        define_method(attribute) { @context.send(attribute) }

        # Define setter
        define_method("#{attribute}=".to_sym) do |value|
          unless @context.to_h.key?(attribute)
            raise <<~ERROR
                    You can't assign a value to an optional parameter if you
                    didn't initialize the interaktor with it in the first
                    place.
                  ERROR
          end

          @context.send("#{attribute}=".to_sym, value)
        end

        # Handle options
        optional_defaults[attribute] = options[:default] if options[:default]
        options.delete(:default)

        raise "Unknown option(s): #{options.keys.join(", ")}" if options.any?
      end
    end

    # A DSL method for documenting required interaktor failure attributes.
    #
    # @param attributes [Symbol, Array<Symbol>] the list of attribute names
    # @param options [Hash]
    #
    # @return [void]
    def failure(*attributes, **options)
      failure_attributes.concat attributes

      attributes.each do |attribute|
        # Handle options
        raise "Unknown option(s): #{options.keys.join(", ")}" if options.any?
      end
    end

    # A DSL method for documenting required interaktor success attributes.
    #
    # @param attributes [Symbol, Array<Symbol>] the list of attribute names
    # @param options [Hash]
    #
    # @return [void]
    def success(*attributes, **options)
      success_attributes.concat attributes

      attributes.each do |attribute|
        # Handle options
        raise "Unknown option(s): #{options.keys.join(", ")}" if options.any?
      end
    end

    # Invoke an Interaktor. This is the primary public API method to an
    # interaktor.
    #
    # @param context [Hash, Interaktor::Context] the context object as a hash
    # with attributes or an already-built context
    #
    # @return [Interaktor::Context] the context, following interaktor execution
    def call(context = {})
      apply_default_optional_attributes(context)
      verify_attribute_presence(context)

      new(context).tap(&:run).instance_variable_get(:@context)
    end

    # Invoke an Interaktor. This method behaves identically to `#call`, with
    # one notable exception - if the context is failed during the invocation of
    # the interaktor, `Interaktor::Failure` is raised.
    #
    # @param context [Hash, Interaktor::Context] the context object as a hash
    # with attributes or an already-built context
    #
    # @raises [Interaktor::Failure]
    #
    # @return [Interaktor::Context] the context, following interaktor execution
    def call!(context = {})
      apply_default_optional_attributes(context)
      verify_attribute_presence(context)

      new(context).tap(&:run!).instance_variable_get(:@context)
    end

    private

    # Check the provided context against the attributes defined with the DSL
    # methods, and determine if there are any attributes which are required and
    # have not been provided, or if there are any attributes which have been
    # provided but are not listed as either required or optional.
    #
    # @param context [Interaktor::Context] the context to check
    #
    # @return [void]
    def verify_attribute_presence(context)
      # TODO: Add "allow_nil?" option to required attributes
      missing_attrs = required_attributes.reject { |required_attr| context.to_h.key?(required_attr) }

      raise <<~ERROR if missing_attrs.any?
        Required attribute(s) were not provided when initializing #{self} interaktor:
          #{missing_attrs.join("\n  ")}
      ERROR

      allowed_attrs = required_attributes + optional_attributes
      extra_attrs = context.to_h.keys.reject { |attr| allowed_attrs.include?(attr) }

      raise <<~ERROR if extra_attrs.any?
        One or more provided attributes were not recognized when initializing #{self} interaktor:
          #{extra_attrs.join("\n  ")}
      ERROR
    end

    # Given the list of optional default attribute values defined by the class,
    # assign those default values to the context if they were omitted.
    #
    # @param context [Interaktor::Context]
    #
    # @return [void]
    def apply_default_optional_attributes(context)
      optional_defaults.each do |attribute, default|
        context[attribute] ||= default
      end
    end
  end
end
