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

      interaction_class = Class.new(Interaktor::Interaction)
      base.const_set(:Interaction, interaction_class)
    end
  end

  module ClassMethods
  end

  # @param args [Hash, Interaktor::Interaction] the context object as a hash
  #   with attributes or an already-built context
  def initialize(args = {})
    @interaction = self.class::Interaction.new(self, args)
  end

  # @param args [Hash{Symbol=>Object}]
  def fail!(args = {})
    # TODO
    # if (disallowed_key = args.keys.find { |k| !self.class.failure_attributes.include?(k.to_sym) })
    #   raise Interaktor::Error::UnknownAttributeError.new(self, disallowed_key)
    # end

    @interaction.fail!(args)
  end

  # @param args [Hash]
  def success!(args = {})
    # TODO
    # if (disallowed_key = args.keys.find { |k| !self.class.success_attributes.include?(k.to_sym) })
    #   raise Interaktor::Error::UnknownAttributeError.new(self, disallowed_key)
    # end

    @interaction.success!(args)
  end

  # Invoke an Interaktor instance without any hooks, tracking, or rollback. It
  # is expected that the `#call` instance method is overwritten for each
  # interaktor class.
  def call
  end

  # Reverse prior invocation of an Interaktor instance. Any interaktor class
  # that requires undoing upon downstream failure is expected to overwrite the
  # `#rollback` instance method.
  def rollback
  end

  # Invoke an interaktor instance along with all defined hooks. The `run` method
  # is used internally by the `call` class method. After successful invocation
  # of the interaktor, the instance is tracked within the context. If the
  # context is failed or any error is raised, the context is rolled back.
  def run
    run!
  rescue Interaktor::Failure
  end

  # Invoke an Interaktor instance along with all defined hooks, typically used
  # internally by `.call!`. After successful invocation of the interaktor, the
  # instance is tracked within the interaction. If the interaction is failed or
  # any error is raised, the interaction is rolled back. This method behaves
  # identically to `#run` with one notable exception - if the interaction is
  # failed during the invocation of the interaktor, `Interaktor::Failure` is
  # raised.
  #
  # @raises [Interaktor::Failure]
  def run!
    with_hooks do
      catch(:early_return) do
        call
      end

      @interaction.called!(self)
    end
  rescue
    @interaction.rollback!
    raise
  end
end
