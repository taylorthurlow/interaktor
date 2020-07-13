shared_examples "lint" do
  let(:interaktor) { Class.new.send(:include, described_class) }

  describe ".call" do
    let(:context) { double(:context) }
    let(:instance) { double(:instance, context: context) }

    it "calls an instance with the given context" do
      expect(interaktor).to receive(:new).once.with(foo: "bar") { instance }
      expect(instance).to receive(:run).once.with(no_args)

      expect(interaktor.call(foo: "bar")).to eq(context)
    end

    it "provides a blank context if none is given" do
      expect(interaktor).to receive(:new).once.with({}) { instance }
      expect(instance).to receive(:run).once.with(no_args)

      expect(interaktor.call).to eq(context)
    end
  end

  describe ".call!" do
    let(:context) { double(:context) }
    let(:instance) { double(:instance, context: context) }

    it "calls an instance with the given context" do
      expect(interaktor).to receive(:new).once.with(foo: "bar") { instance }
      expect(instance).to receive(:run!).once.with(no_args)

      expect(interaktor.call!(foo: "bar")).to eq(context)
    end

    it "provides a blank context if none is given" do
      expect(interaktor).to receive(:new).once.with({}) { instance }
      expect(instance).to receive(:run!).once.with(no_args)

      expect(interaktor.call!).to eq(context)
    end
  end

  describe ".new" do
    let(:context) { double(:context) }

    it "initializes a context" do
      expect(Interaktor::Context).to receive(:build)
                                       .once.with(foo: "bar") { context }

      instance = interaktor.new(foo: "bar")

      expect(instance).to be_a(interaktor)
      expect(instance.context).to eq(context)
    end

    it "initializes a blank context if none is given" do
      expect(Interaktor::Context).to receive(:build).once.with({}) { context }

      instance = interaktor.new

      expect(instance).to be_a(interaktor)
      expect(instance.context).to eq(context)
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
