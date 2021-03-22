RSpec.shared_examples "lint" do |interaktor_class|
  describe ".call" do
    it "calls an instance" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)
      expect(interaktor).to receive(:new).once.with({}).and_call_original

      result = interaktor.call

      expect(result.success?).to be true
    end

    it "fails when an unknown attribute is provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect {
        interaktor.call(baz: "wadus")
      }.to raise_error(
        an_instance_of(Interaktor::Error::AttributeSchemaValidationError).and(
          having_attributes(
            interaktor: interaktor,
            validation_errors: { baz: ["is not allowed"] },
          )
        )
      )
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

    it "fails when an unknown attribute is provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect {
        interaktor.call!(baz: "wadus")
      }.to raise_error(
        an_instance_of(Interaktor::Error::AttributeSchemaValidationError).and(
          having_attributes(
            interaktor: interaktor,
            validation_errors: { baz: ["is not allowed"] },
          )
        )
      )
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

  describe "#failure_attributes" do
    it "returns the attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure :foo, :bar
      end

      expect(interaktor.failure_attributes).to contain_exactly(:foo, :bar)
    end
  end

  describe "#success_attributes" do
    it "returns the attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success :foo, :bar
      end

      expect(interaktor.success_attributes).to contain_exactly(:foo, :bar)
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

    it "raises an exception when an attribute is provided but not included in the schema" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { required(:bar).filled(:string) }
      end

      expect {
        interaktor.call!(bar: "baz", foo: "unexpected")
      }.to raise_error(
        an_instance_of(Interaktor::Error::AttributeSchemaValidationError).and(
          having_attributes(
            interaktor: interaktor,
            validation_errors: { foo: ["is not allowed"] },
          )
        )
      )
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

  describe "required attributes" do
    it "initializes successfully when the attribute is provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { required(:bar) }
      end

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "creates a value setter" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { required(:bar) }

        def call
          self.bar = "wadus"
        end
      end

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "wadus"
    end

    it "raises an exception when the attribute is not provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { required(:bar) }
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
  end

  describe "optional attributes" do
    it "initializes successfully when the attribute is provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { optional(:bar) }
      end

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "initializes successfully when the attribute is not provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { optional(:bar) }
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.bar).to be_nil
    end

    it "creates a value setter" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { optional(:bar) }

        def call
          self.bar = "wadus"
        end
      end

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "wadus"
    end
  end

  describe "success attributes" do
    it "succeeds when the correct attributes are provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success :bar

        def call
          success!(bar: "baz")
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "raises an exception when the correct attributes are not provided because #success! is not called" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) { success :bar }

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar])
        )
      )
    end

    it "raises an exception when the correct attributes are not provided in the call to #success!" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success :bar

        def call
          success!({})
        end
      end

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar])
        )
      )
    end

    it "raises an exception when unknown attributes are provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success :bar

        def call
          success!(bar: "baz", baz: "wadus")
        end
      end

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::UnknownAttributeError).and having_attributes(attributes: [:baz])
        )
      )
    end
  end

  describe "failure attributes" do
    it "fails when the correct attributes are provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure :bar

        def call
          fail!(bar: "baz")
        end
      end

      result = interaktor.call

      expect(result.success?).to be false
      expect(result.bar).to eq "baz"
    end

    it "raises an exception when the correct attributes are not provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure :bar

        def call
          fail!({})
        end
      end

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar])
        )
      )
    end

    context "when the interaktor is called with #call!" do
      it "raises an exception when the correct attributes are provided" do
        interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
          failure :bar

          def call
            fail!(bar: "baz")
          end
        end

        expect { interaktor.call! }.to raise_error(Interaktor::Failure)
      end

      it "raises an exception when the correct attributes are not provided" do
        interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
          failure :bar

          def call
            fail!({})
          end
        end

        expect { interaktor.call }.to(
          raise_error(
            an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar])
          )
        )
      end
    end
  end
end
