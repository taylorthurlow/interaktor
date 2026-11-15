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

    it "raises the failure of an interaktor that it calls with .call!" do
      inner_interaktor = FakeInteraktor.build_interaktor("InnerInteraktor") do
        define_method(:call) { fail! }
      end
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        define_method(:call) { inner_interaktor.call! }
      end

      expect {
        interaktor.call
      }.to raise_error(Interaktor::Failure) { |error|
        expect(error.interaction).to be_an inner_interaktor::Interaction
      }
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
      instance = FakeInteraktor.build_interaktor(type: interaktor_class) do
        define_method(:call) { fail! }
      end.new

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

    it "lets the interaktor read its attributes when it is rolled back" do
      foo_in_rollback = nil
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        input { attribute :foo }

        after { raise "after hook failed" }

        define_method(:rollback) { foo_in_rollback = foo }
      end

      expect {
        interaktor.call(foo: "bar")
      }.to raise_error("after hook failed")

      expect(foo_in_rollback).to eq "bar"
    end

    it "disallows specifically disallowed attribute names" do
      expect {
        FakeInteraktor.build_interaktor(type: interaktor_class) do
          # 'errors' is one because it's the accessor for the ActiveModel::Errors
          input { attribute :errors }
        end
      }.to raise_error(ArgumentError, /disallowed attribute name/i)
    end

    it "disallows the names of methods of the interaktor" do
      expect {
        FakeInteraktor.build_interaktor(type: interaktor_class) do
          input { attribute :run }
        end
      }.to raise_error(ArgumentError, /disallowed attribute name\(s\): run/i)
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

    it "lets the interaktor read its attributes when it is rolled back" do
      foo_in_rollback = nil
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { attribute :foo }

        after { raise "after hook failed" }

        def call
          success!(foo: "bar")
        end

        define_method(:rollback) { foo_in_rollback = foo }
      end

      expect {
        interaktor.call
      }.to raise_error("after hook failed")

      expect(foo_in_rollback).to eq "bar"
    end

    it "lets the interaktor read an input attribute of the same name until it calls #success!" do
      foo_in_call = nil
      foo_in_after_hook = nil
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { attribute :foo }
        input { attribute :foo }

        after { foo_in_after_hook = foo }

        define_method(:call) do
          foo_in_call = foo
          success!(foo: "new")
        end
      end

      interaktor.call(foo: "old")

      expect(foo_in_call).to eq "old"
      expect(foo_in_after_hook).to eq "new"
    end

    it "doesn't hide a method of the same name from a module that the interaktor includes" do
      helpers = Module.new do
        def foo
          "from the module"
        end
      end
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        include helpers

        success { attribute :foo }

        def call
          success!(foo: foo)
        end
      end

      result = interaktor.call

      expect(result.foo).to eq "from the module"
    end

    it "doesn't replace a method of the same name defined before the success block" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        def foo
          "from the method"
        end

        success { attribute :foo }

        def call
          success!(foo: foo)
        end
      end

      result = interaktor.call

      expect(result.foo).to eq "from the method"
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

    it "disallows the names of methods of the interaktor" do
      expect {
        FakeInteraktor.build_interaktor(type: interaktor_class) do
          success { attribute :run }
        end
      }.to raise_error(ArgumentError, /disallowed attribute name\(s\): run/i)
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

  describe "hooks" do
    it "raises an exception when a before hook calls #success!" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        before { success! }
      end

      expect {
        interaktor.call
      }.to raise_error(Interaktor::Error::SuccessInHookError) { |error|
        expect(error.interaktor).to be interaktor
      }
    end

    it "raises an exception when an around hook calls #success!" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        around { |_run_interaktor| success! }
      end

      expect {
        interaktor.call
      }.to raise_error(Interaktor::Error::SuccessInHookError)
    end

    it "lets an around hook run an interaktor that calls #success!" do
      interaktor = FakeInteraktor.build_interaktor(type: interaktor_class) do
        success { attribute :foo }

        around { |run_interaktor| run_interaktor.call }

        def call
          success!(foo: "bar")
        end
      end

      result = interaktor.call

      expect(result.foo).to eq "bar"
    end
  end
end
