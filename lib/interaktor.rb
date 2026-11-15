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

      # Holds the methods that return input and success attributes. Methods
      # defined in the interaktor class, or in modules that it includes later,
      # take priority over them.
      base.const_set(:AttributeMethods, Module.new)
      include base::AttributeMethods
    end
  end

  module ClassMethods
  end

  # @param args [Hash, Interaktor::Interaction] the context object as a hash
  #   with attributes or an already-built context
  def initialize(args = {})
    @interaction = self.class::Interaction.new(self, args)
  end

  # @param args [Hash]
  def fail!(args = {})
    @interaction.fail!(args)
  end

  # @param args [Hash]
  def success!(args = {})
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
  rescue Interaktor::Failure => e
    # A failure of another interaktor, which this one called with `.call!`, is
    # an error for this interaktor rather than a failure of it.
    raise if !e.interaction.equal?(@interaction)
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
