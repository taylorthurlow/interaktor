module Interaktor
  RSpec.describe Organizer do
    let(:interaktor) { FakeInteractor.build_organizer }

    it_behaves_like "lint"

    describe ".organize" do
      let(:interaktor2) { instance_double(Interaktor) }
      let(:interaktor3) { instance_double(Interaktor) }

      it "sets interaktors given class arguments" do
        organizer = FakeInteractor.build_organizer

        expect {
          organizer.organize(interaktor2, interaktor3)
        }.to change(organizer, :organized)
               .from([])
               .to([interaktor2, interaktor3])
      end

      it "sets interaktors given an array of classes" do
        organizer = FakeInteractor.build_organizer

        expect {
          organizer.organize([interaktor2, interaktor3])
        }.to change(organizer, :organized)
               .from([])
               .to([interaktor2, interaktor3])
      end

      it "allows multiple organize calls" do
        organizer = FakeInteractor.build_organizer
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
        organizer = FakeInteractor.build_organizer

        expect(organizer.organized).to eq([])
      end
    end

    describe "#call" do
      it "calls each interaktor in order" do
        organizer = FakeInteractor.build_organizer do
          required :foo
          success :foo
        end

        interaktor1 = FakeInteractor.build_interaktor("Interaktor1") do
          required :foo
          success :foo

          def call
            success!(foo: "bar")
          end
        end

        interaktor2 = FakeInteractor.build_interaktor("Interaktor2") do
          required :foo
          success :foo

          def call
            success!(foo: "baz")
          end
        end

        interaktor3 = FakeInteractor.build_interaktor("Interaktor3") do
          required :foo
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
        organizer = FakeInteractor.build_organizer { required :foo }

        interaktor1 = FakeInteractor.build_interaktor("Interaktor1") do
          required :foo
          success :bar

          def call
            success!(bar: "baz")
          end
        end

        interaktor2 = FakeInteractor.build_interaktor("Interaktor1") do
          required :bar

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
        organizer = FakeInteractor.build_organizer
        interaktor1 = FakeInteractor.build_interaktor("Interaktor1") do
          success :foo

          def call
            success!(foo: "whatever")
          end
        end
        interaktor2 = FakeInteractor.build_interaktor("Interaktor2") do
          success :bar

          def call
            success!(bar: "whatever")
          end
        end
        interaktor3 = FakeInteractor.build_interaktor("Interaktor3") { required :foo, :bar }

        allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2, interaktor3])

        expect(interaktor1).to receive(:call!).once.ordered.and_call_original
        expect(interaktor2).to receive(:call!).once.ordered.and_call_original
        expect(interaktor3).to receive(:call!).once.ordered.and_call_original

        organizer.call
      end

      it "allows an interaktor to accept required attributes from the original organizer" do
        organizer = FakeInteractor.build_organizer { required :foo, :bar }
        interaktor1 = FakeInteractor.build_interaktor("Interaktor1")
        interaktor2 = FakeInteractor.build_interaktor("Interaktor2") { required :foo }
        interaktor3 = FakeInteractor.build_interaktor("Interaktor3") { required :bar }

        allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2, interaktor3])

        expect(interaktor1).to receive(:call!).once.ordered.and_call_original
        expect(interaktor2).to receive(:call!).once.ordered.and_call_original
        expect(interaktor3).to receive(:call!).once.ordered.and_call_original

        organizer.call(foo: "whatever", bar: "baz")
      end

      it "allows an interaktor to accept required attributes from the original organizer AND previous success attributes" do
        organizer = FakeInteractor.build_organizer { required :foo }
        interaktor1 = FakeInteractor.build_interaktor("Interaktor1") do
          success :bar

          def call
            success!(bar: "whatever")
          end
        end
        interaktor2 = FakeInteractor.build_interaktor("Interaktor2") do
          success :baz

          def call
            success!(baz: "whatever")
          end
        end
        interaktor3 = FakeInteractor.build_interaktor("Interaktor3") { required :foo, :bar, :baz }

        allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2, interaktor3])

        expect(interaktor1).to receive(:call!).once.ordered.and_call_original
        expect(interaktor2).to receive(:call!).once.ordered.and_call_original
        expect(interaktor3).to receive(:call!).once.ordered.and_call_original

        organizer.call(foo: "whatever")
      end

      it "raises an exception if an interaktor requires an input attribute not provided by any previous interaktor" do
        organizer = FakeInteractor.build_organizer
        interaktor1 = FakeInteractor.build_interaktor("Interaktor1")
        interaktor2 = FakeInteractor.build_interaktor("Interaktor2") { required :foo }

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
        organizer = FakeInteractor.build_organizer { success :final }
        interaktor1 = FakeInteractor.build_interaktor("Interaktor1")

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
end
