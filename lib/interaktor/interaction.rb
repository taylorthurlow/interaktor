require "active_model"

module Interaktor
  class Interaction
    # @return [InputAttributesModel, nil]
    attr_reader :input_object

    # @return [SuccessAttributesModel, nil]
    attr_reader :success_object

    # @return [FailureAttributesModel, nil]
    attr_reader :failure_object

    # @param interaktor [Interaktor]
    # @param input [Hash, Interaction]
    def initialize(interaktor, input)
      @interaktor = interaktor
      @executed = false
      @failed = false
      @rolled_back = false

      @input_object = if defined?(interaktor.class::InputAttributesModel)
        result = interaktor.class::InputAttributesModel.new

        case input
        when Hash
          input.each do |k, v|
            result.send("#{k}=", v)
          rescue NoMethodError => e
            if e.receiver == result
              raise Interaktor::Error::UnknownAttributeError.new(interaktor, k)
            else
              raise e
            end
          end
        when Interaction
          (input.input_object&.attributes || {})
            .merge(input.success_object&.attributes || {})
            .slice(*result.attribute_names)
            .each { |k, v| result.send("#{k}=", v) }
        else
          raise ArgumentError, "Invalid input type: #{input.class}"
        end

        if !result.valid?
          raise Interaktor::Error::AttributeValidationError.new(@interaktor, result)
        end

        result
      elsif input.is_a?(Hash) && !input.empty?
        raise Interaktor::Error::UnknownAttributeError.new(interaktor, input.keys.first)
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

      if defined?(@interaktor.class::FailureAttributesModel)
        @failure_object = @interaktor.class::FailureAttributesModel.new.tap do |obj|
          args.each do |k, v|
            obj.send("#{k}=", v)
          rescue NoMethodError
            raise Interaktor::Error::UnknownAttributeError.new(@interaktor, k)
          end

          if !obj.valid?
            raise Interaktor::Error::AttributeValidationError.new(@interaktor, obj)
          end
        end
      elsif args.any?
        raise Interaktor::Error::UnknownAttributeError.new(@interaktor, args.keys.first)
      end

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

      if defined?(@interaktor.class::SuccessAttributesModel)
        @success_object = @interaktor.class::SuccessAttributesModel.new.tap do |obj|
          args.each do |k, v|
            obj.send("#{k}=", v)
          rescue NoMethodError
            raise Interaktor::Error::UnknownAttributeError.new(@interaktor, k)
          end

          if !obj.valid?
            raise Interaktor::Error::AttributeValidationError.new(@interaktor, obj)
          end
        end
      elsif args.any?
        raise Interaktor::Error::UnknownAttributeError.new(@interaktor, args.keys.first)
      end

      early_return!
    end

    # Only allow access to arguments when appropriate. Input arguments should be
    # accessible only during the interaction's execution, and after the
    # execution is complete, either the success or failure arguments should be
    # accessible, depending on the outcome.
    def method_missing(method_name, *args, &block)
      method_string = method_name.to_s
      if !@executed && input_object&.attribute_names&.include?(method_string)
        input_object.send(method_string)
      elsif @executed && success? && success_object&.attribute_names&.include?(method_string)
        success_object.send(method_string)
      elsif @executed && failure? && failure_object&.attribute_names&.include?(method_string)
        failure_object.send(method_string)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      input_object&.attribute_names&.include?(method_name) ||
        success_object&.attribute_names&.include?(method_name) ||
        failure_object&.attribute_names&.include?(method_name) ||
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
