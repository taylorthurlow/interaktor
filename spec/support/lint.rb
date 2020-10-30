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

    context "when calling an instance with a required attribute" do
      it "succeeds when the attribute is provided" do
        interaktor.class_eval { required :bar }

        attributes = { bar: "baz" }
        expect(interaktor).to receive(:new).once.with(attributes).and_call_original

        result = interaktor.call(attributes)

        expect(result.success?).to be true
        attributes.each { |attr, value| expect(result.send(attr)).to eq value }
      end

      it "fails when the attribute is not provided" do
        interaktor.class_eval { required :bar }

        expect { interaktor.call }.to raise_error(RuntimeError, /not provided/)
      end
    end

    context "when calling an instance with an optional attribute" do
      it "succeeds when the attribute is provided" do
        interaktor.class_eval { optional :bar }

        attributes = { bar: "baz" }
        expect(interaktor).to receive(:new).once.with(attributes).and_call_original

        result = interaktor.call(attributes)

        expect(result.success?).to be true
        attributes.each { |attr, value| expect(result.send(attr)).to eq value }
      end

      it "succeeds when the attribute is not provided" do
        interaktor.class_eval { optional :bar }

        expect(interaktor).to receive(:new).once.with({}).and_call_original

        result = interaktor.call

        expect(result.success?).to be true
      end
    end

    context "when early-exiting an interaktor with a success" do
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
    end

    context "when exiting an interaktor with a failure" do
      it "fails successfully when the correct attributes are provided" do
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

    context "when calling an instance with a required attribute" do
      it "succeeds when the attribute is provided" do
        interaktor.class_eval { required :bar }

        attributes = { bar: "baz" }
        expect(interaktor).to receive(:new).once.with(attributes).and_call_original

        result = interaktor.call!(attributes)

        expect(result.success?).to be true
        attributes.each { |attr, value| expect(result.send(attr)).to eq value }
      end

      it "fails when the attribute is not provided" do
        interaktor.class_eval { required :bar }

        expect { interaktor.call! }.to raise_error(RuntimeError, /not provided/)
      end
    end

    context "when calling an instance with an optional attribute" do
      it "succeeds when the attribute is provided" do
        interaktor.class_eval { optional :bar }

        attributes = { bar: "baz" }
        expect(interaktor).to receive(:new).once.with(attributes).and_call_original

        result = interaktor.call!(attributes)

        expect(result.success?).to be true
        attributes.each { |attr, value| expect(result.send(attr)).to eq value }
      end

      it "succeeds when the attribute is not provided" do
        interaktor.class_eval { optional :bar }

        expect(interaktor).to receive(:new).once.with({}).and_call_original

        result = interaktor.call!

        expect(result.success?).to be true
      end
    end

    context "when early-exiting an interaktor with a success" do
      it "succeeds when the correct attributes are provided" do
        interaktor.class_eval { success :bar }

        expect(interaktor).to receive(:new).once.with({}).and_call_original

        interaktor.define_method(:call) do
          success!(bar: "baz")
        end

        result = interaktor.call!

        expect(result.success?).to be true
        expect(result.bar).to eq "baz"
      end

      it "raises an exception when the correct attributes are not provided" do
        interaktor.class_eval { success :bar }

        expect(interaktor).to receive(:new).once.with({}).and_call_original

        interaktor.define_method(:call) do
          success!({})
        end

        expect { interaktor.call! }.to raise_error(RuntimeError, /Missing success attrs/)
      end
    end

    context "when exiting an interaktor with a failure" do
      it "fails successfully when the correct attributes are provided" do
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

        expect { interaktor.call! }.to raise_error(RuntimeError, /Missing failure attrs/)
      end
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
end
