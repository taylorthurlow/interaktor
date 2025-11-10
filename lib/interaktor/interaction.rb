module Interaktor
  class Interaction
    attr_reader :input_args, :success_args, :failure_args

    # @param interaktor [Interaktor]
    # @param input [Hash, Interaction]
    def initialize(interaktor, input)
      @interaktor = interaktor
      @executed = false
      @failed = false
      @rolled_back = false

      @input_args = case input
      when Hash
        input.transform_keys(&:to_sym)
      when Interaction
        input
          .input_args
          .merge(input.success_args || {})
          .slice(*(interaktor.class.input_attributes || []))
      else
        raise ArgumentError, "Invalid input type: #{input.class}"
      end
    end

    # Whether the interaction is successful.
    def success?
      if !@executed
        raise Interaktor::Error::InvalidMethodForStateError.new(
          self,
          "Cannot call `success?` before interaktor execution is complete"
        )
      end

      !failure?
    end

    # Whether the interaction has failed.
    def failure?
      if !@executed
        raise Interaktor::Error::InvalidMethodForStateError.new(
          self,
          "Cannot call `failure?` before interaktor execution is complete"
        )
      end

      @failed
    end

    # @param args [Hash]
    #
    # @raises [Interaktor::Failure]
    def fail!(args = {})
      if @executed
        raise Interaktor::Error::InvalidMethodForStateError.new(
          self,
          "Cannot call `fail!` after interaktor execution is already complete"
        )
      end

      @executed = true
      @failed = true
      @failure_args = args.transform_keys(&:to_sym)
      raise Interaktor::Failure, self
    end

    # @param args [Hash]
    def success!(args = {})
      if @executed
        raise Interaktor::Error::InvalidMethodForStateError.new(
          self,
          "Cannot call `success!` after interaktor execution is already complete"
        )
      end

      @executed = true
      @success_args = args.transform_keys(&:to_sym)
      early_return!
    end

    def allowable_success_attributes
      @interaktor.class.success_attributes
    end

    def allowable_failure_attributes
      @interaktor.class.failure_attributes
    end

    # Only allow access to arguments when appropriate. Input arguments should be
    # accessible only during the interaction's execution, and after the
    # execution is complete, either the success or failure arguments should be
    # accessible, depending on the outcome.
    def method_missing(method_name, *args, &block)
      if !@executed && @interaktor.class.input_attributes.include?(method_name)
        input_args[method_name]
      elsif @executed && success? && allowable_success_attributes.include?(method_name)
        success_args[method_name]
      elsif @executed && failure? && allowable_failure_attributes.include?(method_name)
        failure_args[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      input_args.key?(method_name) ||
        success_args&.key?(method_name) ||
        failure_args&.key?(method_name) ||
        super
    end

    # Roll back the interaction. Successful interactions may have this method
    # called to roll back their state.
    #
    # @return [Boolean] true if rolled back successfully, false if already
    #   rolled back
    def rollback!
      return false if @rolled_back

      _called.reverse_each(&:rollback)
      @rolled_back = true
    end

    # Track that an Interaktor has been called. The `#called!` method is used by
    # the interaktor being invoked. After an interaktor is successfully called,
    # the interaction is tracked for the purpose of potential future rollback.
    #
    # @param interaktor [Interaktor] an interaktor that has been successfully
    #   called
    def called!(interaktor)
      @executed = true
      _called << interaktor
    end

    # An array of successfully called Interaktor instances invoked against this
    # interaction instance.
    #
    # @return [Array<Interaktor>]
    def _called
      @called ||= []
    end

    # Trigger an early return throw.
    def early_return!
      @early_return = true
      throw :early_return, self
    end

    # Whether or not the interaction has been returned from early.
    def early_return?
      (@early_return == true) || false
    end
  end
end
