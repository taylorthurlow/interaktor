module Interaktor
  describe Organizer do
    let(:organizer) { Class.new.include(described_class) }

    include_examples "lint"

    describe ".organize" do
      let(:interaktor2) { instance_double(Interaktor) }
      let(:interaktor3) { instance_double(Interaktor) }

      it "sets interaktors given class arguments" do
        expect {
          organizer.organize(interaktor2, interaktor3)
        }.to change(organizer, :organized).from([]).to([interaktor2, interaktor3])
      end

      it "sets interaktors given an array of classes" do
        expect {
          organizer.organize([interaktor2, interaktor3])
        }.to change(organizer, :organized).from([]).to([interaktor2, interaktor3])
      end

      it "allows multiple organize calls" do
        interaktor4 = instance_double(Interaktor)
        expect {
          organizer.organize(interaktor2, interaktor3)
          organizer.organize(interaktor4)
        }.to change(organizer, :organized).from([]).to([interaktor2, interaktor3, interaktor4])
      end
    end

    describe ".organized" do
      it "is empty by default" do
        expect(organizer.organized).to eq([])
      end
    end

    describe "#call" do
      it "calls each interaktor in order" do
        organizer.class_eval { required :foo }

        interaktor2 = Class.new.include(Interaktor)
        interaktor2.class_eval { required :foo }
        interaktor2.define_method(:call) { self.foo = "bar" }

        interaktor3 = Class.new.include(Interaktor)
        interaktor3.class_eval { required :foo }
        interaktor3.define_method(:call) { self.foo = "baz" }

        interaktor4 = Class.new.include(Interaktor)
        interaktor4.class_eval { required :foo }
        interaktor4.define_method(:call) { self.foo = "wadus" }

        allow(organizer).to receive(:organized) {
          [interaktor2, interaktor3, interaktor4]
        }

        expect(interaktor2).to receive(:call!).once.ordered.and_call_original
        expect(interaktor3).to receive(:call!).once.ordered.and_call_original
        expect(interaktor4).to receive(:call!).once.ordered.and_call_original

        result = organizer.call(foo: "asdf")

        expect(result.foo).to eq "wadus"
      end

      it "calls each interaktor in order and passes success attributes" do
        organizer.class_eval { required :foo }

        interaktor2 = Class.new.include(Interaktor)
        interaktor2.class_eval do
          required :foo
          success :bar
        end
        interaktor2.define_method(:call) { success!(bar: "baz") }

        interaktor3 = Class.new.include(Interaktor)
        interaktor3.class_eval { required :bar }
        interaktor3.define_method(:call) { self.bar = "wadus" }

        allow(organizer).to receive(:organized) {
          [interaktor2, interaktor3]
        }

        expect(interaktor2).to receive(:call!).once.ordered.and_call_original
        expect(interaktor3).to receive(:call!).once.ordered.and_call_original

        result = organizer.call(foo: "asdf")

        expect(result.bar).to eq "wadus"
      end

      it "raises an exception if the organizer attributes do not satisfy the first interaktor" do
        organizer.class_eval { required :foo }

        interaktor2 = Class.new.include(Interaktor)
        interaktor2.class_eval { required :bar }

        allow(organizer).to receive(:organized).and_return([interaktor2])

        expect(interaktor2).to receive(:call!).once.ordered.and_call_original

        expect {
          organizer.call(foo: "bar")
        }.to raise_error(an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar]))
      end

      it "raises an exception if the organizer attributes do not satisfy a non-first interaktor" do
        organizer.class_eval { required :foo }

        interaktor2 = Class.new.include(Interaktor)
        interaktor2.class_eval { required :foo }

        interaktor3 = Class.new.include(Interaktor)
        interaktor3.class_eval { required :bar }

        allow(organizer).to receive(:organized).and_return([interaktor2, interaktor3])

        expect(interaktor2).to receive(:call!).once.ordered.and_call_original
        expect(interaktor3).to receive(:call!).once.ordered.and_call_original

        expect {
          organizer.call(foo: "bar")
        }.to raise_error(an_instance_of(Interaktor::Error::MissingAttributeError).and having_attributes(attributes: [:bar]))
      end
    end
  end
end
