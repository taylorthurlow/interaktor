RSpec.describe Interaktor::Organizer do
  it_behaves_like "lint", described_class

  describe ".organize" do
    let(:interaktor2) { instance_double(Interaktor) }
    let(:interaktor3) { instance_double(Interaktor) }

    it "sets interaktors given class arguments" do
      organizer = FakeInteraktor.build_interaktor(type: described_class)

      expect {
        organizer.organize(interaktor2, interaktor3)
      }.to change(organizer, :organized)
        .from([])
        .to([interaktor2, interaktor3])
    end

    it "sets interaktors given an array of classes" do
      organizer = FakeInteraktor.build_interaktor(type: described_class)

      expect {
        organizer.organize([interaktor2, interaktor3])
      }.to change(organizer, :organized)
        .from([])
        .to([interaktor2, interaktor3])
    end

    it "allows multiple organize calls" do
      organizer = FakeInteraktor.build_interaktor(type: described_class)
      interaktor4 = instance_double(Interaktor)

      expect {
        organizer.organize(interaktor2, interaktor3)
        organizer.organize(interaktor4)
      }.to change(organizer, :organized)
        .from([])
        .to([interaktor2, interaktor3, interaktor4])
    end
  end

  describe ".organized" do
    it "is empty by default" do
      organizer = FakeInteraktor.build_interaktor(type: described_class)

      expect(organizer.organized).to eq([])
    end
  end

  describe "#call" do
    it "calls each interaktor in order" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) do
        input { attribute :foo }
        success { attribute :baz }
      end

      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
        input { attribute :foo }
        success { attribute :bar }

        def call
          success!(bar: "whatever")
        end
      end

      interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") do
        input { attribute :bar }
        success { attribute :baz }

        def call
          success!(baz: "whatever")
        end
      end

      allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2])

      expect(interaktor1).to receive(:call!).once.ordered.and_call_original
      expect(interaktor2).to receive(:call!).once.ordered.and_call_original

      result = organizer.call(foo: "asdf")

      expect(result.baz).to eq "whatever"
    end

    it "allows an interaktor to accept input attributes from an organizer" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) do
        input { attribute :foo }
      end

      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
        input { attribute :foo }
        success { attribute :bar }

        def call
          success!(bar: "baz")
        end
      end

      interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") do
        input { attribute :bar }

        def call
        end
      end

      allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2])

      expect(interaktor1).to receive(:call!).once.ordered.and_call_original
      expect(interaktor2).to receive(:call!).once.ordered.and_call_original

      organizer.call(foo: "whatever")
    end

    it "allows an interaktor to accept input attributes from the previous organized interaktor's input attributes" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) { input { attribute :foo } }
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") { input { attribute :foo } }
      interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") do
        input { attribute :foo }
        success { attribute :bar }

        def call
          success!(bar: foo)
        end
      end

      allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2])

      expect(interaktor1).to receive(:call!).once.ordered.and_call_original
      expect(interaktor2).to receive(:call!).once.ordered.and_call_original

      organizer.call(foo: "whatever")
    end

    it "allows an interaktor to accept input attributes from the previous organized interaktor's success attributes" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) { input { attribute :foo } }

      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
        input { attribute :foo }
        success { attribute :bar }

        def call
          success!(bar: foo)
        end
      end

      interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") do
        input { attribute :bar }
        success { attribute :baz }

        def call
          success!(baz: bar)
        end
      end

      allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2])

      expect(interaktor1).to receive(:call!).once.ordered.and_call_original
      expect(interaktor2).to receive(:call!).once.ordered.and_call_original

      organizer.call(foo: "whatever")
    end

    it "raises an exception if an interaktor cannot receive input attribute from the organizer" do
      organizer = FakeInteraktor.build_interaktor(type: described_class)
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
        input do
          attribute :foo
          validates :foo, presence: true
        end
      end

      allow(organizer).to receive(:organized).and_return([interaktor1])

      expect {
        organizer.call
      }.to raise_error do |error|
        expect(error).to be_an Interaktor::Error::AttributeValidationError
        expect(error.validation_errors).to eq(
          foo: ["can't be blank"]
        )
      end
    end

    it "raises an exception if an interaktor cannot receive input attribute from the previous interaktor" do
      organizer = FakeInteraktor.build_interaktor(type: described_class)
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1")
      interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") do
        input do
          attribute :foo
          validates :foo, presence: true
        end
      end

      allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2])

      expect {
        organizer.call
      }.to raise_error do |error|
        expect(error).to be_an Interaktor::Error::AttributeValidationError
        expect(error.validation_errors).to eq(
          foo: ["can't be blank"]
        )
      end
    end

    it "raises an exception if the organizer's last interaktor does not include the organizer's success attributes" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) do
        success do
          attribute :final
          validates :final, presence: true
        end
      end
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1")

      allow(organizer).to receive(:organized).and_return([interaktor1])

      expect {
        organizer.call
      }.to raise_error do |error|
        expect(error).to be_an Interaktor::Error::AttributeValidationError
        expect(error.validation_errors).to eq(
          final: ["can't be blank"]
        )
      end
    end
  end
end
