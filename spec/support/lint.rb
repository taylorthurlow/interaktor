shared_examples "lint" do
  let(:interaktor) do
    klass = Class.new.include(described_class)
    klass.class_eval do
      optional :foo
    end

    klass
  end

  describe ".call" do
    let(:instance) { instance_double(interaktor) }

    it "calls an instance" do
      expect(interaktor).to receive(:new).once.with({}).and_call_original

      result = interaktor.call

      expect(result.success?).to be true
    end

    it "fails when an unknown attribute is provided" do
      expect { interaktor.call(baz: "wadus") }.to raise_error(RuntimeError, /not recognized/)
    end
  end

  describe ".call!" do
    let(:instance) { instance_double(interaktor) }

    it "calls an instance" do
      expect(interaktor).to receive(:new).once.with({}).and_call_original

      result = interaktor.call!

      expect(result.success?).to be true
    end

    it "fails when an unknown attribute is provided" do
      expect { interaktor.call!(baz: "wadus") }.to raise_error(RuntimeError, /not recognized/)
    end
  end

  describe "#run" do
    let(:instance) { interaktor.new }

    it "runs the interaktor" do
      expect(instance).to receive(:run!).once.with(no_args)

      instance.run
    end

    it "rescues failure" do
      expect(instance).to receive(:run!).and_raise(Interaktor::Failure)

      expect {
        instance.run
      }.not_to raise_error
    end

    it "raises other errors" do
      expect(instance).to receive(:run!).and_raise("foo")

      expect {
        instance.run
      }.to raise_error("foo")
    end
  end

  describe "#run!" do
    let(:instance) { interaktor.new }

    it "calls the interaktor" do
      expect(instance).to receive(:call).once.with(no_args)

      instance.run!
    end

    it "raises failure" do
      expect(instance).to receive(:run!).and_raise(Interaktor::Failure)

      expect {
        instance.run!
      }.to raise_error(Interaktor::Failure)
    end

    it "raises other errors" do
      expect(instance).to receive(:run!).and_raise("foo")

      expect {
        instance.run
      }.to raise_error("foo")
    end
  end

  describe "#call" do
    let(:instance) { interaktor.new }

    it "exists" do
      expect(instance).to respond_to(:call)
      expect { instance.call }.not_to raise_error
      expect { instance.method(:call) }.not_to raise_error
    end
  end

  describe "#rollback" do
    let(:instance) { interaktor.new }

    it "exists" do
      expect(instance).to respond_to(:rollback)
      expect { instance.rollback }.not_to raise_error
      expect { instance.method(:rollback) }.not_to raise_error
    end
  end

  describe "required attributes" do
    let(:instance) { instance_double(interaktor) }

    it "initializes successfully when the attribute is provided" do
      interaktor.class_eval { required :bar }

      expect(interaktor).to receive(:new).once.with(bar: "baz").and_call_original

      result = interaktor.call(bar: "baz")

      expect(result.success?).to be true
      expect(result.bar).to eq "baz"
    end

    it "raises an exception when the attribute is not provided" do
      interaktor.class_eval { required :bar }

      expect { interaktor.call }.to raise_error(RuntimeError, /not provided/)
    end

    describe "options" do
      it "raises an exception when an unknown option is provided" do
        expect {
          interaktor.class_eval { required :bar, unknown: true }
        }.to raise_error(RuntimeError, /Unknown option/)
      end
    end
  end

  describe "optional attributes" do
    let(:instance) { instance_double(interaktor) }

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

    it "raises an exception when assigning a value to an optional parameter which was not originally provided" do
      interaktor.class_eval { optional :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      interaktor.define_method(:call) do
        self.bar = "baz"
      end

      expect { interaktor.call }.to raise_exception(RuntimeError, /can't assign a value/)
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
        }.to raise_error(RuntimeError, /Unknown option/)
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

    it "raises an exception when the correct attributes are not provided" do
      interaktor.class_eval { success :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      interaktor.define_method(:call) do
        success!({})
      end

      expect { interaktor.call }.to raise_error(RuntimeError, /Missing success attrs/)
    end

    it "raises an exception when unknown attributes are provided" do
      interaktor.class_eval { success :bar }

      expect(interaktor).to receive(:new).once.with({}).and_call_original

      interaktor.define_method(:call) do
        success!(bar: "baz", baz: "wadus")
      end

      expect { interaktor.call }.to raise_error(RuntimeError, /Unknown success attrs/)
    end

    describe "options" do
      it "raises an exception when an unknown option is provided" do
        expect {
          interaktor.class_eval { success :bar, unknown: true }
        }.to raise_error(RuntimeError, /Unknown option/)
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

      expect { interaktor.call }.to raise_error(RuntimeError, /Missing failure attrs/)
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

        expect { interaktor.call }.to raise_error(RuntimeError, /Missing failure attrs/)
      end
    end

    describe "options" do
      it "raises an exception when an unknown option is provided" do
        expect {
          interaktor.class_eval { failure :bar, unknown: true }
        }.to raise_error(RuntimeError, /Unknown option/)
      end
    end
  end
end
