require "interactor/context"
require "interactor/error"
require "interactor/hooks"
require "interactor/organizer"

module Interactor
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      include Hooks
    end
  end

  def fail!(failure_attributes = {})
    # Make sure we have all required attributes
    missing_attrs = self.class.failure_attributes
                        .reject { |failure_attr| failure_attributes.key?(failure_attr) }
    raise "Missing failure attrs: #{missing_attrs.join(", ")}" if missing_attrs.any?

    @context.fail!(failure_attributes)
  end

  module ClassMethods
    def required_attributes
      @required_attributes ||= []
    end

    def optional_attributes
      @optional_attributes ||= []
    end

    def failure_attributes
      @failure_attributes ||= []
    end

    def required(*attributes)
      required_attributes.concat attributes

      attributes.each do |attribute|
        define_method(attribute) { @context.send(attribute) }
        define_method("#{attribute}=".to_sym) do |value|
          @context.send("#{attribute}=".to_sym, value)
        end
      end
    end

    def optional(*attributes)
      optional_attributes.concat attributes

      attributes.each do |attribute|
        define_method(attribute) { @context.send(attribute) }
        define_method("#{attribute}=".to_sym) do |value|
          unless @context.to_h.keys.include?(attribute)
            raise <<~ERROR
              You can't assign a value to an optional parameter if you didn't
              initialize the interactor with it in the first place.
            ERROR
          end

          @context.send("#{attribute}=".to_sym, value)
        end
      end
    end

    def failure(*attributes)
      failure_attributes.concat attributes
    end

    def call(context = {})
      verify_attributes(context)

      new(context).tap(&:run).instance_variable_get(:@context)
    end

    def call!(context = {})
      verify_attributes(context)

      new(context).tap(&:run!).instance_variable_get(:@context)
    end

    private

    def verify_attributes(context)
      # TODO: Add "allow_nil?" option to required attributes

      # Make sure we have all required attributes
      missing_attrs = required_attributes
                          .reject { |required_attr| context.to_h.key?(required_attr) }
      raise <<~ERROR if missing_attrs.any?
        Required attribute(s) were not provided when initializing #{name} interactor:
          #{missing_attrs.join("\n  ")}
      ERROR
    end
  end

  def initialize(context = {})
    @context = Context.build(context)
  end

  def run
    run!
  rescue Failure
  end

  # Internal: Invoke an Interactor instance along with all defined hooks. The
  # "run!" method is used internally by the "call!" class method. The following
  # are equivalent:
  #
  #   MyInteractor.call!(foo: "bar")
  #   # => #<Interactor::Context foo="bar">
  #
  #   interactor = MyInteractor.new(foo: "bar")
  #   interactor.run!
  #   interactor.context
  #   # => #<Interactor::Context foo="bar">
  #
  # After successful invocation of the interactor, the instance is tracked
  # within the context. If the context is failed or any error is raised, the
  # context is rolled back.
  #
  # The "run!" method behaves identically to the "run" method with one notable
  # exception. If the context is failed during invocation of the interactor,
  # the Interactor::Failure is raised.
  #
  # Returns nothing.
  # Raises Interactor::Failure if the context is failed.
  def run!
    with_hooks do
      call
      @context.called!(self)
    end
  rescue StandardError
    @context.rollback!
    raise
  end

  # Public: Invoke an Interactor instance without any hooks, tracking, or
  # rollback. It is expected that the "call" instance method is overwritten for
  # each interactor class.
  #
  # Returns nothing.
  def call; end

  # Public: Reverse prior invocation of an Interactor instance. Any interactor
  # class that requires undoing upon downstream failure is expected to overwrite
  # the "rollback" instance method.
  #
  # Returns nothing.
  def rollback; end
end
