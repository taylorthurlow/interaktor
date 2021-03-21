RSpec.shared_examples "lint" do
  describe ".call" do
    it "calls an instance" do
      expect(interaktor).to receive(:new).once.with({}).and_call_original

      result = interaktor.call

      expect(result.success?).to be true
    end

    it "fails when an unknown attribute is provided" do
      expect {
        interaktor.call(baz: "wadus")
      }.to raise_error(an_instance_of(Interaktor::Error::UnknownAttributeError).and having_attributes(attributes: [:baz]))
    end

    it "fails when a non-hash or non-context argument is passed" do
      expect {
        interaktor.call("foo")
      }.to raise_error(ArgumentError, /Expected a hash argument/)
    end
  end

  describe ".call!" do
    it "calls an instance" do
      expect(interaktor).to receive(:new).once.with({}).and_call_original

      result = interaktor.call!

      expect(result.success?).to be true
    end

    it "fails when an unknown attribute is provided" do
      expect {
        interaktor.call!(baz: "wadus")
      }.to raise_error(an_instance_of(Interaktor::Error::UnknownAttributeError).and having_attributes(attributes: [:baz]))
    end

    it "fails when a non-hash or non-context argument is passed" do
      expect {
        interaktor.call!("foo")
      }.to raise_error(ArgumentError, /Expected a hash argument/)
    end
  end

  describe "#run" do
    it "runs the interaktor" do
      instance = interaktor.new

      expect(instance).to receive(:run!).once.with(no_args)

      instance.run
    end

    it "rescues failure" do
      instance = interaktor.new

      expect(instance).to receive(:run!).and_raise(Interaktor::Failure)

      expect {
        instance.run
      }.not_to raise_error
    end

    it "raises other errors" do
      instance = interaktor.new

      expect(instance).to receive(:run!).and_raise("foo")

      expect {
        instance.run
      }.to raise_error("foo")
    end
  end

  describe "#run!" do
    it "calls the interaktor" do
      instance = interaktor.new

      expect(instance).to receive(:call).once.with(no_args)

      instance.run!
    end

    it "raises failure" do
      instance = interaktor.new

      expect(instance).to receive(:run!).and_raise(Interaktor::Failure)

      expect {
        instance.run!
      }.to raise_error(Interaktor::Failure)
    end

    it "raises other errors" do
      instance = interaktor.new

      expect(instance).to receive(:run!).and_raise("foo")

      expect {
        instance.run
      }.to raise_error("foo")
    end
  end

  describe "#call" do
    it "exists" do
      instance = interaktor.new

      expect(instance).to respond_to(:call)
      expect { instance.call }.not_to raise_error
      expect { instance.method(:call) }.not_to raise_error
    end
  end

  describe "#rollback" do
    it "exists" do
      instance = interaktor.new

      expect(instance).to respond_to(:rollback)
      expect { instance.rollback }.not_to raise_error
      expect { instance.method(:rollback) }.not_to raise_error
    end
  end

  describe "#required_attributes" do
    it "returns the attributes" do
      interaktor.class_eval { required :foo, :bar }

      expect(interaktor.required_attributes).to contain_exactly(:foo, :bar)
    end
  end

  describe "#optional_attributes" do
    it "returns the attributes" do
      interaktor.class_eval { optional :foo, :bar }

      expect(interaktor.optional_attributes).to contain_exactly(:foo, :bar)
    end
  end

  describe "#input_attributes" do
    it "returns both required and optional attributes" do
      interaktor.class_eval do
        required :foo
        optional :bar
      end

      expect(interaktor.required_attributes).to contain_exactly(:foo)
      expect(interaktor.optional_attributes).to contain_exactly(:bar)
      expect(interaktor.input_attributes).to contain_exactly(:foo, :bar)
    end
  end

  describe "#failure_attributes" do
    it "returns the attributes" do
      interaktor.class_eval { failure :foo, :bar }

      expect(interaktor.failure_attributes).to contain_exactly(:foo, :bar)
    end
  end

  describe "#success_attributes" do
    it "returns the attributes" do
      interaktor.class_eval { success :foo, :bar }

      expect(interaktor.success_attributes).to contain_exactly(:foo, :bar)
    end
  end

  describe "#optional_defaults" do
    it "returns the default value hash" do
      interaktor.class_eval do
        optional :foo, default: "bar"
        optional :baz, default: "wadus"
      end

      expect(interaktor.optional_defaults).to eq(
        foo: "bar",
        baz: "wadus",
      )
    end
  end

  describe "required attributes" do
    it "initializes successfully when the attribute is provided" do
      interaktor.class_eval { required :bar }

      expect(interaktor).to receive(:new).once.with(bar: "baz").and_call_original

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "creates a value setter" do
      interaktor.class_eval { required :bar }

      expect(interaktor).to receive(:new).once.with(bar: "baz").and_call_original

      interaktor.define_method(:call) do
        self.bar = "wadus"
      end

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "wadus"
    end

    it "raises an exception when the attribute is not provided" do
      interaktor.class_eval { required :bar }

      expect {
        interaktor.call!
      }.to raise_error(an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar]))
    end

    describe "options" do
      it "raises an exception when an unknown option is provided" do
        expect {
          interaktor.class_eval { required :bar, unknown: true }
        }.to raise_error(an_instance_of(Interaktor::Error::UnknownOptionError).and having_attributes(options: { unknown: true }))
      end
    end
  end

  describe "optional attributes" do
    it "initializes successfully when the attribute is provided" do
      interaktor.class_eval { optional :bar }

      expect(interaktor).to receive(:new).once.with(bar: "baz").and_call_original

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "initializes successfully when the attribute is not provided" do
      interaktor.class_eval { optional :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.bar).to be_nil
    end

    it "creates a value setter" do
      interaktor.class_eval { optional :bar }

      expect(interaktor).to receive(:new).once.with(bar: "baz").and_call_original

      interaktor.define_method(:call) do
        self.bar = "wadus"
      end

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "wadus"
    end

    it "raises an exception when assigning a value to an optional parameter which was not originally provided" do
      interaktor.class_eval { optional :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      interaktor.define_method(:call) do
        self.bar = "baz"
      end

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::DisallowedAttributeAssignmentError)
            .and(having_attributes(attributes: [:bar]))
        )
      )
    end

    describe "options" do
      it "accepts a default value for the attribute" do
        interaktor.class_eval { optional :bar, default: "baz" }

        expect(interaktor).to receive(:new).once.with(bar: "baz").and_call_original

        result = interaktor.call

        expect(result.success?).to be true
        expect(result.bar).to eq "baz"
      end

      it "raises an exception when an unknown option is provided" do
        expect {
          interaktor.class_eval { optional :bar, unknown: true }
        }.to raise_error(an_instance_of(Interaktor::Error::UnknownOptionError).and having_attributes(options: { unknown: true }))
      end
    end
  end

  describe "success attributes" do
    it "succeeds when the correct attributes are provided" do
      interaktor.class_eval { success :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      interaktor.define_method(:call) do
        success!(bar: "baz")
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "raises an exception when the correct attributes are not provided because #success! is not called" do
      interaktor.class_eval { success :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar])
        )
      )
    end

    it "raises an exception when the correct attributes are not provided in the call to #success!" do
      interaktor.class_eval { success :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      interaktor.define_method(:call) do
        success!({})
      end

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar])
        )
      )
    end

    it "raises an exception when unknown attributes are provided" do
      interaktor.class_eval { success :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      interaktor.define_method(:call) do
        success!(bar: "baz", baz: "wadus")
      end

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::UnknownAttributeError).and having_attributes(attributes: [:baz])
        )
      )
    end

    describe "options" do
      it "raises an exception when an unknown option is provided" do
        expect {
          interaktor.class_eval { success :bar, unknown: true }
        }.to raise_error(an_instance_of(Interaktor::Error::UnknownOptionError).and having_attributes(options: { unknown: true }))
      end
    end
  end

  describe "failure attributes" do
    it "fails when the correct attributes are provided" do
      interaktor.class_eval { failure :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      interaktor.define_method(:call) do
        fail!(bar: "baz")
      end

      result = interaktor.call

      expect(result.success?).to be false
      expect(result.bar).to eq "baz"
    end

    it "raises an exception when the correct attributes are not provided" do
      interaktor.class_eval { failure :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      interaktor.define_method(:call) do
        fail!({})
      end

      expect { interaktor.call }.to(
        raise_error(
          an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar])
        )
      )
    end

    context "when the interaktor is called with #call!" do
      it "raises an exception when the correct attributes are provided" do
        interaktor.class_eval { failure :bar }

        expect(interaktor).to receive(:new).once.with({}).and_call_original

        interaktor.define_method(:call) do
          fail!(bar: "baz")
        end

        expect { interaktor.call! }.to raise_error(Interaktor::Failure)
      end

      it "raises an exception when the correct attributes are not provided" do
        interaktor.class_eval { failure :bar }

        expect(interaktor).to receive(:new).once.with({}).and_call_original

        interaktor.define_method(:call) do
          fail!({})
        end

        expect { interaktor.call }.to(
          raise_error(
            an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar])
          )
        )
      end
    end

    describe "options" do
      it "raises an exception when an unknown option is provided" do
        expect {
          interaktor.class_eval { failure :bar, unknown: true }
        }.to raise_error(an_instance_of(Interaktor::Error::UnknownOptionError).and having_attributes(options: { unknown: true }))
      end
    end
  end
end
