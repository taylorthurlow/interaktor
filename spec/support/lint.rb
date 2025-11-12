RSpec.shared_examples "lint" do |interaktor_class|
  describe ".call" do
    it "calls an instance" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)
      expect(interaktor).to receive(:new).once.with({}).and_call_original

      result = interaktor.call

      expect(result.success?).to be true
    end

    it "raises an exception for unknown provided attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect {
        interaktor.call(foo: "bar")
      }.to raise_error(Interaktor::Error::UnknownAttributeError)
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

    it "raises an exception for unknown provided attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class)

      expect {
        interaktor.call!(baz: "wadus")
      }.to raise_error(Interaktor::Error::UnknownAttributeError)
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

  describe "input attributes" do
    it "accepts an attribute definition block" do
      interaktor = FakeInteraktor.build_interaktor("MyCoolFoo", type: interaktor_class) do
        input { attribute :foo }
      end

      result = interaktor.call(foo: "bar")

      expect(result.success?).to be true
      expect { result.foo }.to raise_error(NoMethodError)
    end

    it "raises an exception when the attribute is required and not provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input do
          attribute :foo
          validates :foo, presence: true
        end
      end

      expect {
        interaktor.call!
      }.to raise_error do |error|
        expect(error).to be_an Interaktor::Error::AttributeValidationError
        expect(error.validation_errors).to eq(
          foo: ["can't be blank"]
        )
      end
    end

    it "raises an exception for unknown provided attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { attribute :foo }
      end

      expect {
        interaktor.call!(foo: "baz", bar: "unexpected")
      }.to raise_error do |error|
        expect(error).to be_an Interaktor::Error::UnknownAttributeError
        expect(error.attribute).to eq "bar"
      end
    end

    it "allows provided optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { attribute :foo }
      end

      result = interaktor.call(foo: "bar")

      expect(result.success?).to be true
      expect { result.foo }.to raise_error(NoMethodError)
    end

    it "allows missing optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { attribute :foo }
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect { result.foo }.to raise_error(NoMethodError)
    end

    it "creates attribute getters" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { attribute :foo }

        def call
          foo
        end
      end

      result = interaktor.call(foo: "bar")

      expect(result.success?).to be true
      expect { result.foo }.to raise_error(NoMethodError)
      expect { result.bar }.to raise_error(NoMethodError)
    end

    it "disallows specifically disallowed attribute names" do
      expect {
        FakeInteraktor.build_interaktor(type: interaktor_class) do
          # 'errors' is one because it's the accessor for the ActiveModel::Errors
          input { attribute :errors }
        end
      }.to raise_error(ArgumentError, /disallowed attribute name/i)
    end

    it "raises an exception when input block is provided more than once" do
      expect {
        FakeInteraktor.build_interaktor(type: interaktor_class) do
          input { attribute :foo }
          input { attribute :bar }
        end
      }.to raise_error "Input block already defined"
    end
  end

  describe "success attributes" do
    it "accepts an attribute definition block" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { attribute :foo }

        def call
          success!(foo: "bar")
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.foo).to eq "bar"
    end

    it "raises an exception when the attribute is required and not provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success do
          attribute :foo
          validates :foo, presence: true
        end

        def call
          success!
        end
      end

      expect {
        interaktor.call!
      }.to raise_error do |error|
        expect(error).to be_an Interaktor::Error::AttributeValidationError
        expect(error.validation_errors).to eq(
          foo: ["can't be blank"]
        )
      end
    end

    it "raises an exception for unknown provided attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { attribute :foo }

        def call
          success!(baz: "wadus")
        end
      end

      expect {
        interaktor.call
      }.to raise_error do |error|
        expect(error).to be_an Interaktor::Error::UnknownAttributeError
        expect(error.attribute).to eq "baz"
      end
    end

    it "allows success with no attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        def call
          success!
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.early_return?).to be true
    end

    it "allows provided optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { attribute :foo }

        def call
          success!(foo: "bar")
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.foo).to eq "bar"
    end

    it "allows missing optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { attribute :foo }

        def call
          success!
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.foo).to be nil
    end

    it "raises an exception when attributes are provided but none are defined" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        def call
          success!(foo: "bar")
        end
      end

      expect {
        interaktor.call
      }.to raise_error do |error|
        expect(error).to be_a Interaktor::Error::UnknownAttributeError
        expect(error.attribute).to eq "foo"
      end
    end

    it "raises an exception when the correct attributes are not provided because #success! is not called" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { attribute :foo }

        def call
          # do nothing and 'succeed' implicitly
        end
      end

      expect { interaktor.call }.to raise_error Interaktor::Error::MissingExplicitSuccessError
    end

    it "does not create getters for failure attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { attribute :foo }
        failure { attribute :baz }

        def call
          success!(foo: "bar")
        end
      end

      result = interaktor.call

      expect(result.success?).to be true
      expect(result.foo).to eq "bar"
      expect { result.baz }.to raise_error NoMethodError
    end

    it "disallows specifically disallowed attribute names" do
      expect {
        FakeInteraktor.build_interaktor(type: interaktor_class) do
          # 'errors' is one because it's the accessor for the ActiveModel::Errors
          success { attribute :errors }
        end
      }.to raise_error(ArgumentError, /disallowed attribute name/i)
    end

    it "raises an exception when success block is provided more than once" do
      expect {
        FakeInteraktor.build_interaktor(type: interaktor_class) do
          success { attribute :foo }
          success { attribute :bar }
        end
      }.to raise_error "Success block already defined"
    end
  end

  describe "failure attributes" do
    it "accepts an attribute definition block" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { attribute :foo }

        def call
          fail!(foo: "bar")
        end
      end

      result = interaktor.call

      expect(result.failure?).to be true
      expect(result.foo).to eq "bar"
    end

    it "raises an exception when the attribute is required and not provided" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure do
          attribute :foo
          validates :foo, presence: true
        end

        def call
          fail!
        end
      end

      expect {
        interaktor.call!
      }.to raise_error do |error|
        expect(error).to be_an Interaktor::Error::AttributeValidationError
        expect(error.validation_errors).to eq(
          foo: ["can't be blank"]
        )
      end
    end

    it "raises an exception for unknown provided attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { attribute :foo }

        def call
          fail!(baz: "wadus")
        end
      end

      expect {
        interaktor.call
      }.to raise_error do |error|
        expect(error).to be_an Interaktor::Error::UnknownAttributeError
        expect(error.attribute).to eq "baz"
      end
    end

    it "allows failure with no attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        def call
          fail!
        end
      end

      result = interaktor.call

      expect(result.failure?).to be true
    end

    it "raises an exception when attributes are provided but none are defined" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        def call
          fail!(foo: "bar")
        end
      end

      expect {
        interaktor.call
      }.to raise_error do |error|
        expect(error).to be_a Interaktor::Error::UnknownAttributeError
        expect(error.attribute).to eq "foo"
      end
    end

    it "allows provided optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { attribute :foo }

        def call
          fail!(foo: "bar")
        end
      end

      result = interaktor.call

      expect(result.failure?).to be true
      expect(result.foo).to eq "bar"
    end

    it "allows missing optional attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        failure { attribute :foo }

        def call
          fail!
        end
      end

      result = interaktor.call

      expect(result.failure?).to be true
      expect(result.foo).to be nil
    end

    it "does not create getters for success attributes" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { attribute :foo }
        failure { attribute :baz }

        def call
          fail!(baz: "wadus")
        end
      end

      result = interaktor.call

      expect(result.failure?).to be true
      expect(result.baz).to eq "wadus"
      expect { result.foo }.to raise_error NoMethodError
    end

    it "disallows specifically disallowed attribute names" do
      expect {
        FakeInteraktor.build_interaktor(type: interaktor_class) do
          # 'errors' is one because it's the accessor for the ActiveModel::Errors
          failure { attribute :errors }
        end
      }.to raise_error(ArgumentError, /disallowed attribute name/i)
    end

    it "raises an exception when failure block is provided more than once" do
      expect {
        FakeInteraktor.build_interaktor(type: interaktor_class) do
          failure { attribute :foo }
          failure { attribute :bar }
        end
      }.to raise_error "Failure block already defined"
    end
  end
end
