require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
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

    # @return [Interaktor::Context] this should not be used publicly
    attr_accessor :context
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

    # The list of attributes which are required to be passed in when calling
    # `#fail!` from within the interaktor.
    #
    # @return [Array<Symbol>]
    def failure_attributes
      @failure_attributes ||= []
    end

    # A DSL method for documenting required interaktor attributes.
    #
    # @param attributes [Symbol, Array<Symbol>] the list of attribute names
    #
    # @return [void]
    def required(*attributes)
      required_attributes.concat attributes

      attributes.each do |attribute|
        define_method(attribute) { context.send(attribute) }
        define_method("#{attribute}=".to_sym) do |value|
          context.send("#{attribute}=".to_sym, value)
        end
      end
    end

    # A DSL method for documenting optional interaktor attributes.
    #
    # @param attributes [Symbol, Array<Symbol>] the list of attribute names
    #
    # @return [void]
    def optional(*attributes)
      optional_attributes.concat attributes

      attributes.each do |attribute|
        define_method(attribute) { context.send(attribute) }
        define_method("#{attribute}=".to_sym) do |value|
          unless context.to_h.key?(attribute)
            raise <<~ERROR
                    You can't assign a value to an optional parameter if you didn't
                    initialize the interaktor with it in the first place.
                  ERROR
          end

          context.send("#{attribute}=".to_sym, value)
        end
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

    # Invoke an Interaktor. This is the primary public API method to an
    # interaktor.
    #
    # @param context [Hash, Interaktor::Context] the context object as a hash
    # with attributes or an already-built context
    #
    # @return [Interaktor::Context] the context, following interaktor execution
    def call(context = {})
      verify_attribute_presence(context)

      new(context).tap(&:run).context
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

      new(context).tap(&:run!).context
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

    context.fail!(failure_attributes)
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
      context.called!(self)
    end
  rescue StandardError
    context.rollback!
    raise
  end
end
