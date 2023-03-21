RSpec.shared_examples "lint" do |interaktor_class|
  describe ".call" do
    it "calls an instance" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)
      expect(interaktor).to receive(:new).once.with({}).and_call_original

      result = interaktor.call

      expect(result.success?).to be true
    end

    it "removes unknown provided attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      result = interaktor.call(baz: "wadus")

      expect(result.baz).to be nil
    end

    it "fails when a non-hash or non-context argument is passed" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect {
        interaktor.call("foo")
      }.to raise_error(ArgumentError, /Expected a hash argument/)
    end
  end

  describe ".call!" do
    it "calls an instance" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)
      expect(interaktor).to receive(:new).once.with({}).and_call_original

      result = interaktor.call!

      expect(result.success?).to be true
    end

    it "removes unknown provided attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      result = interaktor.call!(baz: "wadus")

      expect(result.baz).to be nil
    end

    it "fails when a non-hash or non-context argument is passed" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect {
        interaktor.call!("foo")
      }.to raise_error(ArgumentError, /Expected a hash argument/)
    end
  end

  describe "#run" do
    it "runs the interaktor" do
      instance = FakeInteraktor.build_interaktor(type: interaktor_class).new

      expect(instance).to receive(:run!).once.with(no_args)

      instance.run
    end

    it "rescues failure" do
      instance = FakeInteraktor.build_interaktor(type: interaktor_class).new

      expect(instance).to receive(:run!).and_raise(Interaktor::Failure)

      expect {
        instance.run
      }.not_to raise_error
    end

    it "raises other errors" do
      instance = FakeInteraktor.build_interaktor(type: interaktor_class).new

      expect(instance).to receive(:run!).and_raise("foo")

      expect {
        instance.run
      }.to raise_error("foo")
    end
  end

  describe "#run!" do
    it "calls the interaktor" do
      instance = FakeInteraktor.build_interaktor(type: interaktor_class).new

      expect(instance).to receive(:call).once.with(no_args)

      instance.run!
    end

    it "raises failure" do
      instance = FakeInteraktor.build_interaktor(type: interaktor_class).new

      expect(instance).to receive(:run!).and_raise(Interaktor::Failure)

      expect {
        instance.run!
      }.to raise_error(Interaktor::Failure)
    end

    it "raises other errors" do
      instance = FakeInteraktor.build_interaktor(type: interaktor_class).new

      expect(instance).to receive(:run!).and_raise("foo")

      expect {
        instance.run
      }.to raise_error("foo")
    end
  end

  describe "#call" do
    it "exists" do
      instance = FakeInteraktor.build_interaktor(type: interaktor_class).new

      expect(instance).to respond_to(:call)
      expect { instance.call }.not_to raise_error
      expect { instance.method(:call) }.not_to raise_error
    end
  end

  describe "#rollback" do
    it "exists" do
      instance = FakeInteraktor.build_interaktor(type: interaktor_class).new

      expect(instance).to respond_to(:rollback)
      expect { instance.rollback }.not_to raise_error
      expect { instance.method(:rollback) }.not_to raise_error
    end
  end

  describe "#required_input_attributes" do
    it "returns the attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input do
          required(:foo)
          required(:bar)
          optional(:baz)
        end
      end

      expect(interaktor.required_input_attributes).to contain_exactly(:foo, :bar)
    end

    it "returns empty array when not defined" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect(interaktor.required_input_attributes).to be_empty
    end
  end

  describe "#optional_input_attributes" do
    it "returns the attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input do
          required(:foo)
          required(:bar)
          optional(:baz)
        end
      end

      expect(interaktor.optional_input_attributes).to contain_exactly(:baz)
    end

    it "returns empty array when not defined" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect(interaktor.optional_input_attributes).to be_empty
    end
  end

  describe "#input_attributes" do
    it "returns both required and optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input do
          required(:foo)
          required(:bar)
          optional(:baz)
        end
      end

      expect(interaktor.input_attributes).to contain_exactly(:foo, :bar, :baz)
    end
  end

  describe "#required_success_attributes" do
    it "returns the attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success do
          required(:foo)
          required(:bar)
          optional(:baz)
        end
      end

      expect(interaktor.required_success_attributes).to contain_exactly(:foo, :bar)
    end

    it "returns empty array when not defined" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect(interaktor.required_success_attributes).to be_empty
    end
  end

  describe "#optional_success_attributes" do
    it "returns the attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success do
          required(:foo)
          required(:bar)
          optional(:baz)
        end
      end

      expect(interaktor.optional_success_attributes).to contain_exactly(:baz)
    end

    it "returns empty array when not defined" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect(interaktor.optional_success_attributes).to be_empty
    end
  end

  describe "#success_attributes" do
    it "returns both required and optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success do
          required(:foo)
          required(:bar)
          optional(:baz)
        end
      end

      expect(interaktor.success_attributes).to contain_exactly(:foo, :bar, :baz)
    end
  end

  describe "#required_failure_attributes" do
    it "returns the attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure do
          required(:foo)
          required(:bar)
          optional(:baz)
        end
      end

      expect(interaktor.required_failure_attributes).to contain_exactly(:foo, :bar)
    end

    it "returns empty array when not defined" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect(interaktor.required_failure_attributes).to be_empty
    end
  end

  describe "#optional_failure_attributes" do
    it "returns the attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure do
          required(:foo)
          required(:bar)
          optional(:baz)
        end
      end

      expect(interaktor.optional_failure_attributes).to contain_exactly(:baz)
    end

    it "returns empty array when not defined" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect(interaktor.optional_failure_attributes).to be_empty
    end
  end

  describe "#failure_attributes" do
    it "returns both required and optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure do
          required(:foo)
          required(:bar)
          optional(:baz)
        end
      end

      expect(interaktor.failure_attributes).to contain_exactly(:foo, :bar, :baz)
    end
  end

  describe "input attributes" do
    it "accepts a schema object" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input(Dry::Schema.Params { required(:bar).filled(:string) })
      end

      expect(interaktor.input_schema).to be_a Dry::Schema::Params
      expect(interaktor.input_schema.info).to eq(
        keys: { bar: { required: true, type: "string" } },
      )

      expect(interaktor.required_input_attributes).to contain_exactly(:bar)

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "accepts a schema definition block" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { required(:bar).filled(:string) }
      end

      expect(interaktor.input_schema).to be_a Dry::Schema::Params
      expect(interaktor.input_schema.info).to eq(
        keys: { bar: { required: true, type: "string" } },
      )

      expect(interaktor.required_input_attributes).to contain_exactly(:bar)

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "raises an exception when the attribute is required and not provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { required(:bar).filled(:string) }
      end

      expect {
        interaktor.call!
      }.to raise_error(
        an_instance_of(Interaktor::Error::AttributeSchemaValidationError).and(
          having_attributes(
            interaktor: interaktor,
            validation_errors: { bar: ["is missing"] },
          )
        )
      )
    end

    it "removes unknown provided attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { required(:bar).filled(:string) }
      end

      result = interaktor.call!(bar: "baz", foo: "unexpected")

      expect(result.foo).to be nil
    end

    it "allows provided optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { optional(:bar).filled(:string) }
      end

      expect(interaktor.optional_input_attributes).to contain_exactly(:bar)

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "allows missing optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { optional(:bar).filled(:string) }
      end

      expect(interaktor.optional_input_attributes).to contain_exactly(:bar)

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.bar).to be_nil
    end

    it "creates attribute getters and setters" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input do
          required(:foo).filled(:string)
          optional(:bar).filled(:string)
        end

        def call
          foo
          bar

          self.foo = "one"
          self.bar = "two"
        end
      end

      result = interaktor.call(foo: "bar", bar: "baz")

      expect(result.success?).to be true
      expect(result.foo).to eq "one"
      expect(result.bar).to eq "two"
    end
  end

  describe "success attributes" do
    it "accepts a schema object" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success(Dry::Schema.Params { required(:bar).filled(:string) })

        def call
          success!(bar: "baz")
        end
      end

      expect(interaktor.success_schema).to be_a Dry::Schema::Params
      expect(interaktor.success_schema.info).to eq(
        keys: { bar: { required: true, type: "string" } },
      )

      expect(interaktor.required_success_attributes).to contain_exactly(:bar)

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "accepts a schema definition block" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { required(:bar).filled(:string) }

        def call
          success!(bar: "baz")
        end
      end

      expect(interaktor.success_schema).to be_a Dry::Schema::Params
      expect(interaktor.success_schema.info).to eq(
        keys: { bar: { required: true, type: "string" } },
      )

      expect(interaktor.required_success_attributes).to contain_exactly(:bar)

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "raises an exception when the attribute is required and not provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { required(:bar).filled(:string) }

        def call
          success!
        end
      end

      expect {
        result = interaktor.call
      }.to raise_error(
        an_instance_of(Interaktor::Error::AttributeSchemaValidationError).and(
          having_attributes(
            interaktor: interaktor,
            validation_errors: { bar: ["is missing"] },
          )
        )
      )
    end

    it "removes unknown provided attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { required(:bar).filled(:string) }

        def call
          success!(bar: "baz", foo: "wadus")
        end
      end

      result = interaktor.call

      expect(result.foo).to be nil
    end

    it "allows missing optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { optional(:bar).filled(:string) }

        def call
          success!
        end
      end

      expect(interaktor.optional_success_attributes).to contain_exactly(:bar)

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.bar).to be nil
    end

    it "raises an exception when the correct attributes are not provided because #success! is not called" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { required(:bar).filled(:string) }

        def call
          # do nothing and succeed implicitly
        end
      end

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::MissingExplicitSuccessError).and having_attributes(attributes: [:bar])
        )
      )
    end
  end

  describe "failure attributes" do
    it "accepts a schema object" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure(Dry::Schema.Params { required(:bar).filled(:string) })

        def call
          fail!(bar: "baz")
        end
      end

      expect(interaktor.failure_schema).to be_a Dry::Schema::Params
      expect(interaktor.failure_schema.info).to eq(
        keys: { bar: { required: true, type: "string" } },
      )

      expect(interaktor.required_failure_attributes).to contain_exactly(:bar)

      result = interaktor.call

      expect(result.failure?).to be true
      expect(result.bar).to eq "baz"
    end

    it "accepts a schema definition block" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { required(:bar).filled(:string) }

        def call
          fail!(bar: "baz")
        end
      end

      expect(interaktor.failure_schema).to be_a Dry::Schema::Params
      expect(interaktor.failure_schema.info).to eq(
        keys: { bar: { required: true, type: "string" } },
      )

      expect(interaktor.required_failure_attributes).to contain_exactly(:bar)

      result = interaktor.call

      expect(result.failure?).to be true
      expect(result.bar).to eq "baz"
    end

    it "raises an exception when the attribute is required and not provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { required(:bar).filled(:string) }

        def call
          fail!
        end
      end

      expect {
        result = interaktor.call
      }.to raise_error(
        an_instance_of(Interaktor::Error::AttributeSchemaValidationError).and(
          having_attributes(
            interaktor: interaktor,
            validation_errors: { bar: ["is missing"] },
          )
        )
      )
    end

    it "removes unknown provided attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { required(:bar).filled(:string) }

        def call
          fail!(bar: "baz", foo: "wadus")
        end
      end

      result = interaktor.call

      expect(result.foo).to be nil
    end

    it "allows missing optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { optional(:bar).filled(:string) }

        def call
          fail!
        end
      end

      expect(interaktor.optional_failure_attributes).to contain_exactly(:bar)

      result = interaktor.call

      expect(result.failure?).to be true
      expect(result.bar).to be nil
    end
  end

  describe "exception handlers" do
    it "handles an exception and succeeds implicitly when provided an existing proc" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        handler_proc = ->(_e) { "do some stuff" }
        handle_exception StandardError, with: handler_proc

        def call
          raise StandardError, "it broke"
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
    end

    it "handles an exception and succeeds explicitly when provided an existing proc" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { required(:foo) }

        handler_proc = ->(_e) { success!(foo: "bar") }
        handle_exception StandardError, with: handler_proc

        def call
          raise StandardError, "it broke"
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.foo).to eq "bar"
    end

    it "handles an exception and succeeds implicitly when provided a block" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        handle_exception(StandardError) { "do some stuff" }

        def call
          raise StandardError, "it broke"
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
    end

    it "handles an exception and succeeds explicitly when provided a block" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { required(:foo) }

        handle_exception(StandardError) { success!(foo: "bar") }

        def call
          raise StandardError, "it broke"
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.foo).to eq "bar"
    end

    it "handles an exception and succeeds implicitly when no proc or block provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        handle_exception(StandardError)

        def call
          raise StandardError, "it broke"
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
    end

    it "handles an exception and fails when provided an existing proc" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { required(:foo) }

        handler_proc = ->(_e) { fail!(foo: "bar") }
        handle_exception StandardError, with: handler_proc

        def call
          raise StandardError, "it broke"
        end
      end

      result = interaktor.call

      expect(result.success?).to be false
      expect(result.foo).to eq "bar"
    end

    it "handles an exception and fails when provided a block" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { required(:foo) }

        handle_exception(StandardError) { fail!(foo: "bar") }

        def call
          raise StandardError, "it broke"
        end
      end

      result = interaktor.call

      expect(result.success?).to be false
      expect(result.foo).to eq "bar"
    end

    it "accepts multiple exception classes as constants or strings" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { required(:exception_class) }
        failure { required(:message) }

        handle_exception StandardError, "RuntimeError"

        def call
          raise exception_class
        end
      end

      result = interaktor.call(exception_class: StandardError)
      expect(result.success?).to be true

      result = interaktor.call(exception_class: RuntimeError)
      expect(result.success?).to be true

      expect {
        interaktor.call(exception_class: Exception)
      }.to raise_error(Exception)
    end

    it "raises an exception if the handler succeeds but is missing success attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { required(:foo) }

        handle_exception StandardError

        def call
          raise StandardError, "it broke but that's ok"
        end
      end

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::MissingExplicitSuccessError).and(
            having_attributes(
              interaktor: interaktor,
              attributes: [:foo],
            )
          )
        )
      )
    end

    it "raises an exception if the handler fails and is missing failure attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { required(:foo) }

        handle_exception(StandardError) { fail! }

        def call
          raise StandardError, "it broke"
        end
      end

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::AttributeSchemaValidationError).and(
            having_attributes(
              interaktor: interaktor,
              validation_errors: { foo: ["is missing"] },
            )
          )
        )
      )
    end

    it "correctly raises exceptions that occur in the handler" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        handle_exception(RuntimeError) { raise StandardError, "some other problem" }

        def call
          raise RuntimeError, "it broke" # rubocop:disable Style/RedundantException
        end
      end

      expect { interaktor.call }.to(raise_error(StandardError, "some other problem"))
    end

    it "raises an exception if both a block and proc and provided" do
      expect {
        FakeInteraktor.build_interaktor(type: interaktor_class) do
          handle_exception(StandardError, with: ->(_e) { "stuff" }) do
            "stuff"
          end
        end
      }.to(raise_error(Interaktor::Error::InvalidExceptionHandlerError))
    end

    it "allows multiple calls to handle_exception" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { required(:exception_class) }
        success { required(:message) }

        handle_exception(StandardError) { success!(message: "foo") }
        handle_exception(RuntimeError) { success!(message: "bar") }

        def call
          raise exception_class
        end
      end

      result = interaktor.call(exception_class: StandardError)
      expect(result.success?).to be true
      expect(result.message).to eq "foo"

      result = interaktor.call(exception_class: RuntimeError)
      expect(result.success?).to be true
      expect(result.message).to eq "bar"
    end
  end
end
