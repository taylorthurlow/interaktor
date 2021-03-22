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
        input { required(:foo) }
        success :foo
      end

      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
        input { required(:foo) }
        success :foo

        def call
          success!(foo: "bar")
        end
      end

      interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") do
        input { required(:foo) }
        success :foo

        def call
          success!(foo: "baz")
        end
      end

      interaktor3 = FakeInteraktor.build_interaktor("Interaktor3") do
        input { required(:foo) }
        success :foo

        def call
          success!(foo: "wadus")
        end
      end

      allow(organizer).to receive(:organized) {
        [interaktor1, interaktor2, interaktor3]
      }

      expect(interaktor1).to receive(:call!).once.ordered.and_call_original
      expect(interaktor2).to receive(:call!).once.ordered.and_call_original
      expect(interaktor3).to receive(:call!).once.ordered.and_call_original

      result = organizer.call(foo: "asdf")

      expect(result.foo).to eq "wadus"
    end

    it "calls each interaktor in order and passes success attributes" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) { input { required(:foo) } }

      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
        input { required(:foo) }
        success :bar

        def call
          success!(bar: "baz")
        end
      end

      interaktor2 = FakeInteraktor.build_interaktor("Interaktor1") do
        input { required(:bar) }

        def call
          self.bar = "wadus"
        end
      end

      allow(organizer).to receive(:organized) {
        [interaktor1, interaktor2]
      }

      expect(interaktor1).to receive(:call!).once.ordered.and_call_original
      expect(interaktor2).to receive(:call!).once.ordered.and_call_original

      result = organizer.call(foo: "asdf")

      expect(result.bar).to eq "wadus"
    end

    it "allows an interaktor to accept required attributes from previous success attributes" do
      organizer = FakeInteraktor.build_interaktor(type: described_class)
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
        success :foo

        def call
          success!(foo: "whatever")
        end
      end
      interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") do
        success :bar

        def call
          success!(bar: "whatever")
        end
      end
      interaktor3 = FakeInteraktor.build_interaktor("Interaktor3") do
        input do
          required(:foo)
          required(:bar)
        end
      end

      allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2, interaktor3])

      expect(interaktor1).to receive(:call!).once.ordered.and_call_original
      expect(interaktor2).to receive(:call!).once.ordered.and_call_original
      expect(interaktor3).to receive(:call!).once.ordered.and_call_original

      organizer.call
    end

    it "allows an interaktor to accept required attributes from the original organizer" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) do
        input do
          required(:foo)
          required(:bar)
        end
      end
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1")
      interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") { input { required(:foo) } }
      interaktor3 = FakeInteraktor.build_interaktor("Interaktor3") { input { required(:bar) } }

      allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2, interaktor3])

      expect(interaktor1).to receive(:call!).once.ordered.and_call_original
      expect(interaktor2).to receive(:call!).once.ordered.and_call_original
      expect(interaktor3).to receive(:call!).once.ordered.and_call_original

      organizer.call(foo: "whatever", bar: "baz")
    end

    it "allows an interaktor to accept required attributes from the original organizer AND previous success attributes" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) { input { required(:foo) } }
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
        success :bar

        def call
          success!(bar: "whatever")
        end
      end
      interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") do
        success :baz

        def call
          success!(baz: "whatever")
        end
      end
      interaktor3 = FakeInteraktor.build_interaktor("Interaktor3") do
        input do
          required(:foo)
          required(:bar)
          required(:baz)
        end
      end

      allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2, interaktor3])

      expect(interaktor1).to receive(:call!).once.ordered.and_call_original
      expect(interaktor2).to receive(:call!).once.ordered.and_call_original
      expect(interaktor3).to receive(:call!).once.ordered.and_call_original

      organizer.call(foo: "whatever")
    end

    it "raises an exception if an interaktor requires an input attribute not provided by any previous interaktor" do
      organizer = FakeInteraktor.build_interaktor(type: described_class)
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1")
      interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") { input { required(:foo) } }

      allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2])

      expect(interaktor1).not_to receive(:call!)

      expect {
        organizer.call
      }.to raise_error(
        an_instance_of(Interaktor::Error::OrganizerMissingPassedAttributeError)
          .and(having_attributes(
            attribute: :foo,
            interaktor: interaktor2,
          ))
      )
    end

    it "raises an exception if the organizer's last interaktor does not include the organizer's success attributes" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) { success :final }
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1")

      allow(organizer).to receive(:organized).and_return([interaktor1])

      expect(interaktor1).not_to receive(:call!)

      expect {
        organizer.call
      }.to raise_error(
        an_instance_of(Interaktor::Error::OrganizerSuccessAttributeMissingError)
          .and(having_attributes(attribute: :final, interaktor: interaktor1))
      )
    end
  end
end
