require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.push_dir(File.expand_path("../lib", __dir__))
loader.setup

module Interaktor
  # When the Interaktor module is included in a class, add the relevant class
  # methods and hooks to that class.
  #
  # @param base [Class] the class which is including the Interaktor module
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      include Hooks
    end
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
    #
    # @return [void]
    def required(*attributes)
      required_attributes.concat attributes

      attributes.each do |attribute|
        define_method(attribute) { @context.send(attribute) }
        define_method("#{attribute}=".to_sym) do |value|
          @context.send("#{attribute}=".to_sym, value)
        end
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
    #
    # @return [void]
    def failure(*attributes)
      failure_attributes.concat attributes
    end

    # A DSL method for documenting required interaktor success attributes.
    #
    # @param attributes [Symbol, Array<Symbol>] the list of attribute names
    #
    # @return [void]
    def success(*attributes)
      success_attributes.concat attributes
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

      catch(:early_return) do
        new(context).tap(&:run).instance_variable_get(:@context)
      end
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
      verify_attribute_presence(context)

      catch(:early_return) do
        new(context).tap(&:run!).instance_variable_get(:@context)
      end
    end

    private

    # Check the provided context against the attributes defined with the DSL
    # methods, and determine if there are any attributes which are required and
    # have not been provided.
    #
    # @param context [Interaktor::Context] the context to check
    #
    # @return [void]
    def verify_attribute_presence(context)
      # TODO: Add "allow_nil?" option to required attributes
      missing_attrs = required_attributes.reject { |required_attr| context.to_h.key?(required_attr) }

      raise <<~ERROR if missing_attrs.any?
        Required attribute(s) were not provided when initializing #{name} interaktor:
          #{missing_attrs.join("\n  ")}
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

  # @param context [Hash, Interaktor::Context] the context object as a hash
  #   with attributes or an already-built context
  def initialize(context = {})
    @context = Interaktor::Context.build(context)
  end

  # Fail the current interaktor.
  #
  # @param failure_attributes [Hash{Symbol=>Object}] the context attributes
  #
  # @return [void]
  def fail!(failure_attributes = {})
    # Make sure we have all required attributes
    missing_attrs = self.class.failure_attributes
                        .reject { |failure_attr| failure_attributes.key?(failure_attr) }
    raise "Missing failure attrs: #{missing_attrs.join(", ")}" if missing_attrs.any?

    @context.fail!(failure_attributes)
  end

  # Terminate execution of the current interaktor and copy the success
  # attributes into the context.
  #
  # @param success_attributes [Hash{Symbol=>Object}] the context attributes
  #
  # @return [void]
  def success!(success_attributes = {})
    # Make sure we have all required attributes
    missing_attrs = self.class.success_attributes
                        .reject { |success_attr| success_attributes.key?(success_attr) }
    raise "Missing success attrs: #{missing_attrs.join(", ")}" if missing_attrs.any?

    # Make sure we haven't provided any unknown attributes
    unknown_attrs = success_attributes.keys
                                      .reject { |success_attr| self.class.success_attributes.include?(success_attr) }
    raise "Unknown success attrs: #{unknown_attrs.join(", ")}" if unknown_attrs.any?

    @context.success!(success_attributes)
  end

  # Invoke an Interaktor instance without any hooks, tracking, or rollback. It
  # is expected that the `#call` instance method is overwritten for each
  # interaktor class.
  #
  # @return [void]
  def call; end

  # Reverse prior invocation of an Interaktor instance. Any interaktor class
  # that requires undoing upon downstream failure is expected to overwrite the
  # `#rollback` instance method.
  #
  # @return [void]
  def rollback; end

  # Invoke an interaktor instance along with all defined hooks. The `run`
  # method is used internally by the `call` class method. After successful
  # invocation of the interaktor, the instance is tracked within the context.
  # If the context is failed or any error is raised, the context is rolled
  # back.
  #
  # @return [void]
  def run
    run!
  rescue Interaktor::Failure # rubocop:disable Lint/SuppressedException
  end

  # Invoke an Interaktor instance along with all defined hooks, typically used
  # internally by `.call!`. After successful invocation of the interaktor, the
  # instance is tracked within the context. If the context is failed or any
  # error is raised, the context is rolled back. This method behaves
  # identically to `#run` with one notable exception - if the context is failed
  # during the invocation of the interaktor, `Interaktor::Failure` is raised.
  #
  # @raises [Interaktor::Failure]
  #
  # @return [void]
  def run!
    with_hooks do
      call
      @context.called!(self)
    end
  rescue StandardError
    @context.rollback!
    raise
  end
end
