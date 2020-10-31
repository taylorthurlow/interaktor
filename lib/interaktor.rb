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
      include Callable
    end
  end

  module ClassMethods
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
    missing_attrs = self.class
                        .failure_attributes
                        .reject { |failure_attr| failure_attributes.key?(failure_attr) }
    raise Interaktor::Error::MissingAttributeError.new(self.class.to_s, missing_attrs) if missing_attrs.any?

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
    missing_attrs = self.class
                        .success_attributes
                        .reject { |success_attr| success_attributes.key?(success_attr) }
    raise Interaktor::Error::MissingAttributeError.new(self.class.to_s, missing_attrs) if missing_attrs.any?

    # Make sure we haven't provided any unknown attributes
    unknown_attrs = success_attributes.keys
                                      .reject { |success_attr| self.class.success_attributes.include?(success_attr) }
    raise Interaktor::Error::UnknownAttributeError.new(self.class.to_s, unknown_attrs) if unknown_attrs.any?

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
      catch(:early_return) do
        call
      end

      @context.called!(self)
    end
  rescue StandardError
    @context.rollback!
    raise
  end
end
