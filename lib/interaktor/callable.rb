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
    ####################
    # INPUT ATTRIBUTES #
    ####################

    # The list of attributes which are required to be passed in when calling
    # the interaktor.
    #
    # @return [Array<Symbol>]
    def required_input_attributes
      @required_input_attributes ||= input_schema
        .info[:keys]
        .select { |_, info| info[:required] }
        .keys
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

    # Get the input attribute schema. Fall back to an empty schema with a
    # configuration that will deny ALL provided attributes - not defining an
    # input schema should mean the interaktor has no input attributes.
    #
    # @return [Dry::Schema::Params]
    def input_schema
      @input_schema || Dry::Schema.Params
    end

    # @param args [Hash]
    def validate_input_schema(args)
      return if !input_schema

      if (errors = input_schema.call(args).errors).any?
        raise Interaktor::Error::AttributeSchemaValidationError.new(
          self,
          errors.to_h
        )
      end
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
        @input_schema = Dry::Schema.Params { instance_eval(&block) }
      end

      # define the getters and setters for the input attributes
      @input_schema.key_map.keys.each do |key| # rubocop:disable Style/HashEachMethods
        attribute_name = key.id

        # Define getter
        define_method(attribute_name) { @interaction.send(attribute_name) }

        # Define setter
        define_method(:"#{attribute_name}=") do |value|
          @interaction.send(:"#{attribute_name}=", value)
        end
      end
    end

    ######################
    # FAILURE ATTRIBUTES #
    ######################

    # The list of attributes which are required to be provided when failing the
    # interaktor.
    #
    # @return [Array<Symbol>]
    def required_failure_attributes
      @required_failure_attributes ||= failure_schema.info[:keys]
        .select { |_, info| info[:required] }
        .keys
    end

    # The list of attributes which are not required to be provided when failing
    # the interaktor.
    #
    # @return [Array<Symbol>]
    def optional_failure_attributes
      # Adding an optional attribute with NO predicates with Dry::Schema is
      # sort of a "nothing statement" - the schema can sort of ignore it. The
      # problem is that the optional-with-no-predicate key is not included in
      # the #info results, so we need to find an list of keys elsewhere, find
      # the ones that are listed there but not in the #info results, and find
      # the difference. The result are the keys that are omitted from the #info
      # result because they are optional and have no predicates.
      #
      # See https://github.com/dry-rb/dry-schema/issues/347
      @optional_failure_attributes ||= begin
        attributes_in_info = failure_schema.info[:keys].keys
        all_attributes = failure_schema.key_map.keys.map(&:id)
        optional_attributes_by_exclusion = all_attributes - attributes_in_info

        explicitly_optional_attributes = failure_schema.info[:keys].reject { |_, info| info[:required] }.keys

        explicitly_optional_attributes + optional_attributes_by_exclusion
      end
    end

    # The complete list of failure attributes.
    #
    # @return [Array<Symbol>]
    def failure_attributes
      required_failure_attributes + optional_failure_attributes
    end

    # Get the failure attribute schema. Fall back to an empty schema with a
    # configuration that will deny ALL provided attributes - not defining an
    # failure schema should mean the interaktor has no failure attributes.
    #
    # @return [Dry::Schema::Params]
    def failure_schema
      @failure_schema || Dry::Schema.Params
    end

    # @param args [Hash]
    #
    # @return [void]
    def validate_failure_schema(args)
      return if !failure_schema

      if (errors = failure_schema.call(args).errors).any?
        raise Interaktor::Error::AttributeSchemaValidationError.new(
          self,
          errors.to_h
        )
      end
    end

    # @param schema [Dry::Schema::Params, nil] a predefined schema object
    # @yield a new Dry::Schema::Params definition block
    def failure(schema = nil, &block)
      raise "No schema or schema definition block provided to interaktor failure method." if schema.nil? && !block

      raise "Provided both a schema and a schema definition block for interaktor failure method." if schema && block

      if schema
        raise "Provided argument is not a Dry::Schema::Params object." unless schema.is_a?(Dry::Schema::Params)

        @failure_schema = schema
      elsif block
        @failure_schema = Dry::Schema.Params { instance_eval(&block) }
      end
    end

    ######################
    # SUCCESS ATTRIBUTES #
    ######################

    # The list of attributes which are required to be provided when the
    # interaktor succeeds.
    #
    # @return [Array<Symbol>]
    def required_success_attributes
      @required_success_attributes ||= success_schema.info[:keys]
        .select { |_, info| info[:required] }
        .keys
    end

    # The list of attributes which are not required to be provided when failing
    # the interaktor.
    #
    # @return [Array<Symbol>]
    def optional_success_attributes
      # Adding an optional attribute with NO predicates with Dry::Schema is
      # sort of a "nothing statement" - the schema can sort of ignore it. The
      # problem is that the optional-with-no-predicate key is not included in
      # the #info results, so we need to find an list of keys elsewhere, find
      # the ones that are listed there but not in the #info results, and find
      # the difference. The result are the keys that are omitted from the #info
      # result because they are optional and have no predicates.
      #
      # See https://github.com/dry-rb/dry-schema/issues/347
      @optional_success_attributes ||= begin
        attributes_in_info = success_schema.info[:keys].keys
        all_attributes = success_schema.key_map.keys.map(&:id)
        optional_attributes_by_exclusion = all_attributes - attributes_in_info

        explicitly_optional_attributes = success_schema.info[:keys].reject { |_, info| info[:required] }.keys

        explicitly_optional_attributes + optional_attributes_by_exclusion
      end
    end

    # The complete list of success attributes.
    #
    # @return [Array<Symbol>]
    def success_attributes
      required_success_attributes + optional_success_attributes
    end

    # Get the success attribute schema. Fall back to an empty schema with a
    # configuration that will deny ALL provided attributes - not defining an
    # success schema should mean the interaktor has no success attributes.
    #
    # @return [Dry::Schema::Params]
    def success_schema
      @success_schema || Dry::Schema.Params
    end

    # @param args [Hash]
    def validate_success_schema(args)
      return if !success_schema

      if (errors = success_schema.call(args).errors).any?
        raise Interaktor::Error::AttributeSchemaValidationError.new(
          self,
          errors.to_h
        )
      end
    end

    # @param schema [Dry::Schema::Params, nil] a predefined schema object
    # @yield a new Dry::Schema::Params definition block
    def success(schema = nil, &block)
      raise "No schema or schema definition block provided to interaktor success method." if schema.nil? && !block

      raise "Provided both a schema and a schema definition block for interaktor success method." if schema && block

      if schema
        raise "Provided argument is not a Dry::Schema::Params object." unless schema.is_a?(Dry::Schema::Params)

        @success_schema = schema
      elsif block
        @success_schema = Dry::Schema.Params { instance_eval(&block) }
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
      run_method = raise_exception ? :run! : :run

      case args
      when Hash
        if (disallowed_key = args.keys.find { |k| !input_attributes.include?(k.to_sym) })
          raise Interaktor::Error::UnknownAttributeError.new(self, disallowed_key)
        end

        validate_input_schema(args)
        new(args).tap(&run_method).instance_variable_get(:@interaction)
      when Interaktor::Interaction
        new(args).tap(&run_method).instance_variable_get(:@interaction)
      else
        raise ArgumentError,
          "Expected a hash argument when calling the interaktor, got a #{args.class} instead."
      end
    end
  end
end
