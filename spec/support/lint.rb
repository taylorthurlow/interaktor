shared_examples "lint" do
  let(:interaktor) do
    klass = Class.new.include(described_class)
    klass.class_eval do
      optional :foo
    end

    klass
  end

  describe ".call" do
    let(:context) { instance_double(Interaktor::Context) }
    let(:instance) { instance_double(interaktor) }

    it "calls an instance with the given context" do
      instance.instance_variable_set(:@context, context)
      expect(interaktor).to receive(:new).once.with(foo: "bar").and_return(instance)
      expect(instance).to receive(:run).once.with(no_args)

      resulting_context = interaktor.call(foo: "bar")

      expect(resulting_context).to eq(context)
    end

    it "provides a blank context if none is given" do
      instance.instance_variable_set(:@context, context)
      expect(interaktor).to receive(:new).once.with({}).and_return(instance)
      expect(instance).to receive(:run).once.with(no_args)

      resulting_context = interaktor.call({})

      expect(resulting_context).to eq(context)
    end
  end

  describe ".call!" do
    let(:context) { instance_double(Interaktor::Context) }
    let(:instance) { instance_double(interaktor) }

    it "calls an instance with the given context" do
      instance.instance_variable_set(:@context, context)
      expect(interaktor).to receive(:new).once.with(foo: "bar").and_return(instance)
      expect(instance).to receive(:run!).once.with(no_args)

      resulting_context = interaktor.call!(foo: "bar")

      expect(resulting_context).to eq(context)
    end

    it "provides a blank context if none is given" do
      instance.instance_variable_set(:@context, context)
      expect(interaktor).to receive(:new).once.with({}).and_return(instance)
      expect(instance).to receive(:run!).once.with(no_args)

      resulting_context = interaktor.call!({})

      expect(resulting_context).to eq(context)
    end
  end

  describe ".new" do
    let(:context) { instance_double(Interaktor::Context) }

    it "initializes a context" do
      expect(Interaktor::Context).to receive(:build).once.with(foo: "bar").and_return(context)

      instance = interaktor.new(foo: "bar")

      expect(instance).to be_an(interaktor)
      expect(instance.instance_variable_get(:@context)).to eq(context)
    end

    it "initializes a blank context if none is given" do
      expect(Interaktor::Context).to receive(:build).once.with({}).and_return(context)

      instance = interaktor.new

      expect(instance).to be_a(interaktor)
      expect(instance.instance_variable_get(:@context)).to eq(context)
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
