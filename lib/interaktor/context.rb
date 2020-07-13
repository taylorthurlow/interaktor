require "ostruct"

# The object for tracking state of an Interaktor's invocation. The context is
# used to initialize the interaktor with the information required for
# invocation. The interaktor manipulates the context to produce the result of
# invocation. The context is the mechanism by which success and failure are
# determined and the context is responsible for tracking individual interaktor
# invocations for the purpose of rollback. It may be manipulated using
# arbitrary getter and setter methods.
class Interaktor::Context < OpenStruct
  # Initialize an Interaktor::Context or preserve an existing one. If the
  # argument given is an Interaktor::Context, the argument is returned.
  # Otherwise, a new Interaktor::Context is initialized from the provided hash.
  # Used during interaktor initialization.
  #
  # @param context [Hash, Interaktor::Context] the context object as a hash
  # with attributes or an already-built context
  #
  # @return [Interaktor::Context]
  def self.build(context = {})
    context.is_a?(Interaktor::Context) ? context : new(context)
  end

  # Whether the Interaktor::Context is successful. By default, a new context is
  # successful and only changes when explicitly failed. This method is the
  # inverse of the `#failure?` method.
  #
  # @return [Boolean] true by default, or false if failed
  def success?
    !failure?
  end

  # Whether the Interaktor::Context has failed. By default, a new context is
  # successful and only changes when explicitly failed. This method is the
  # inverse of the `#success?` method.
  #
  # @return [Boolean] false by default, or true if failed
  def failure?
    @failure || false
  end

  # Fail the Interaktor::Context. Failing a context raises an error that may be
  # rescued by the calling interaktor. The context is also flagged as having
  # failed. Optionally the caller may provide a hash of key/value pairs to be
  # merged into the context before failure.
  #
  # @param context [Hash] data to be merged into the existing context
  #
  # @raises [Interaktor::Failure]
  #
  # @return [void]
  def fail!(context = {})
    context.each { |key, value| self[key.to_sym] = value }
    @failure = true
    raise Interaktor::Failure, self
  end

  # @param context [Hash] data to be merged into the existing context
  #
  # @raises [Interaktor::Failure]
  #
  # @return [void]
  def success!(context = {})
    context.each { |key, value| self[key.to_sym] = value }
    throw :early_return, self
  end

  # Roll back the Interaktor::Context. Any interaktors to which this context
  # has been passed and which have been successfully called are asked to roll
  # themselves back by invoking their `#rollback` methods.
  #
  # @return [Boolean] true if rolled back successfully, false if already
  #   rolled back
  def rollback!
    return false if @rolled_back

    _called.reverse_each(&:rollback)
    @rolled_back = true
  end

  # Track that an Interaktor has been called. The `#called!` method is used by
  # the interaktor being invoked with this context. After an interaktor is
  # successfully called, the interaktor instance is tracked in the context for
  # the purpose of potential future rollback.
  #
  # @param interaktor [Interaktor] an interaktor that has been successfully
  #   called
  #
  # @return [void]
  def called!(interaktor)
    _called << interaktor
  end

  # An array of successfully called Interaktor instances invoked against this
  # Interaktor::Context instance.
  #
  # @return [Array<Interaktor>]
  def _called
    @called ||= []
  end
end
