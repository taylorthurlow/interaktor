require "ostruct"

# The object for tracking state of an Interactor's invocation. The context is
# used to initialize the interactor with the information required for
# invocation. The interactor manipulates the context to produce the result of
# invocation. The context is the mechanism by which success and failure are
# determined and the context is responsible for tracking individual interactor
# invocations for the purpose of rollback. It may be manipulated using
# arbitrary getter and setter methods.
class Interactor::Context < OpenStruct
  # Initialize an Interactor::Context or preserve an existing one. If the
  # argument given is an Interactor::Context, the argument is returned.
  # Otherwise, a new Interactor::Context is initialized from the provided hash.
  # Used during interactor initialization.
  #
  # @param context [Hash, Interactor::Context] the context object as a hash
  # with attributes or an already-built context
  #
  # @return [Interactor::Context]
  def self.build(context = {})
    context.is_a?(Interactor::Context) ? context : new(context)
  end

  # Whether the Interactor::Context is successful. By default, a new context is
  # successful and only changes when explicitly failed. This method is the
  # inverse of the `#failure?` method.
  #
  # @return [Boolean] true by default, or false if failed
  def success?
    !failure?
  end

  # Whether the Interactor::Context has failed. By default, a new context is
  # successful and only changes when explicitly failed. This method is the
  # inverse of the `#success?` method.
  #
  # @return [Boolean] false by default, or true if failed
  def failure?
    @failure || false
  end

  # Fail the Interactor::Context. Failing a context raises an error that may be
  # rescued by the calling interactor. The context is also flagged as having
  # failed. Optionally the caller may provide a hash of key/value pairs to be
  # merged into the context before failure.
  #
  # @param context [Hash] data to be merged into the existing context
  #
  # @raises [Interactor::Failure]
  #
  # @return [void]
  def fail!(context = {})
    context.each { |key, value| self[key.to_sym] = value }
    @failure = true
    raise Interactor::Failure, self
  end

  # Roll back the Interactor::Context. Any interactors to which this context
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

  # Track that an Interactor has been called. The `#called!` method is used by
  # the interactor being invoked with this context. After an interactor is
  # successfully called, the interactor instance is tracked in the context for
  # the purpose of potential future rollback.
  #
  # @param interactor [Interactor] an interactor that has been successfully
  #   called
  #
  # @return [void]
  def called!(interactor)
    _called << interactor
  end

  # An array of successfully called Interactor instances invoked against this
  # Interactor::Context instance.
  #
  # @return [Array<Interactor>]
  def _called
    @called ||= []
  end
end
