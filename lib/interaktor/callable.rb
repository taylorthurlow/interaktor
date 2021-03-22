require "dry-schema"

Dry::Schema.load_extensions(:info)

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
    def required_input_attributes
      @required_input_attributes ||= input_schema.info[:keys].select { |_, info| info[:required] }.keys
    end

    # The list of attributes which are not required to be passed in when
    # calling the interaktor.
    #
    # @return [Array<Symbol>]
    def optional_input_attributes
      # Adding an optional attribute with NO predicates with Dry::Schema is
      # sort of a "nothing statement" - the schema can sort of ignore it. The
      # problem is that the optional-with-no-predicate key is not included in
      # the #info results, so we need to find an list of keys elsewhere, find
      # the ones that are listed there but not in the #info results, and find
      # the difference. The result are the keys that are omitted from the #info
      # result because they are optional and have no predicates.
      #
      # See https://github.com/dry-rb/dry-schema/issues/347
      @optional_input_attributes ||= begin
          attributes_in_info = input_schema.info[:keys].keys
          all_attributes = input_schema.key_map.keys.map(&:id)
          optional_attributes_by_exclusion = all_attributes - attributes_in_info

          explicitly_optional_attributes = input_schema.info[:keys].reject { |_, info| info[:required] }.keys

          explicitly_optional_attributes + optional_attributes_by_exclusion
        end
    end

    # The complete list of input attributes.
    #
    # @return [Array<Symbol>]
    def input_attributes
      required_input_attributes + optional_input_attributes
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

    # Get the input attribute schema. Fall back to an empty schema with a
    # configuration that will deny ALL provided attributes - not defining an
    # input schema should mean the interaktor has no input attributes.
    #
    # @return [Dry::Schema::Params]
    def input_schema
      @input_schema || Dry::Schema.Params { config.validate_keys = true }
    end

    # @param schema [Dry::Schema::Params, nil] a predefined schema object
    # @yield a new Dry::Schema::Params definition block
    def input(schema = nil, &block)
      raise "No schema or schema definition block provided to interaktor input." if schema.nil? && !block

      raise "Provided both a schema and a schema definition block for interaktor input." if schema && block

      if schema
        raise "Provided argument is not a Dry::Schema::Params object." unless schema.is_a?(Dry::Schema::Params)

        @input_schema = schema
      elsif block
        @input_schema = Dry::Schema.Params do
          # Assume we want to reject unknown attributes, but allow a provided
          # schema definition block to further modify the config if desired
          config.validate_keys = true

          instance_eval(&block)
        end
      end

      # define the getters and setters for the input attributes
      @input_schema.key_map.keys.each do |key| # rubocop:disable Style/HashEachMethods
        attribute_name = key.id

        # Define getter
        define_method(attribute_name) { @context.send(attribute_name) }

        # Define setter
        define_method("#{attribute_name}=".to_sym) do |value|
          @context.send("#{attribute_name}=".to_sym, value)
        end
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
        raise Interaktor::Error::UnknownOptionError.new(self.class.to_s, options) if options.any?
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
        raise Interaktor::Error::UnknownOptionError.new(self.class.to_s, options) if options.any?
      end
    end

    # Invoke an Interaktor. This is the primary public API method to an
    # interaktor. Interaktor failures will not raise an exception.
    #
    # @param context [Hash, Interaktor::Context] the context object as a hash
    #   with attributes or an already-built context
    #
    # @return [Interaktor::Context] the context, following interaktor execution
    def call(context = {})
      execute(context, false)
    end

    # Invoke an Interaktor. This method behaves identically to `#call`, but if
    # the interaktor is failed, `Interaktor::Failure` is raised.
    #
    # @param context [Hash, Interaktor::Context] the context object as a hash
    #   with attributes or an already-built context
    #
    # @raises [Interaktor::Failure]
    #
    # @return [Interaktor::Context] the context, following interaktor execution
    def call!(context = {})
      execute(context, true)
    end

    private

    # The main execution method triggered by the public `#call` or `#call!`
    # methods.
    #
    # @param context [Hash, Interaktor::Context] the context object as a hash
    #   with attributes or an already-built context
    # @param raise_exception [Boolean] whether or not to raise exception on
    #   failure
    #
    # @raises [Interaktor::Failure]
    #
    # @return [Interaktor::Context] the context, following interaktor execution
    def execute(context, raise_exception)
      run_method = raise_exception ? :run! : :run

      case context
      when Hash
        validate_schema(context)

        new(context).tap(&run_method).instance_variable_get(:@context)
      when Interaktor::Context
        new(context).tap(&run_method).instance_variable_get(:@context)
      else
        raise ArgumentError,
              "Expected a hash argument when calling the interaktor, got a #{context.class} instead."
      end
    end

    # @param context [Hash]
    #
    # @return [void]
    def validate_schema(context)
      return unless input_schema

      result = input_schema.call(context)

      if result.errors.any?
        raise Interaktor::Error::AttributeSchemaValidationError.new(
          self,
          result.errors.to_h,
        )
      end
    end
  end
end
