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
      it "calls each interaktor in order with the context" do
        instance = organizer.new
        context = instance_double(Interaktor::Context)
        interaktor2 = class_double(Class.new.include(Interaktor))
        interaktor3 = class_double(Class.new.include(Interaktor))
        interaktor4 = class_double(Class.new.include(Interaktor))

        allow(instance).to receive(:context).and_return(context)
        instance.instance_variable_set(:@context, context)
        allow(organizer).to receive(:organized) {
          [interaktor2, interaktor3, interaktor4]
        }

        expect(interaktor2).to receive(:call!).once.with(context).ordered
        expect(interaktor3).to receive(:call!).once.with(context).ordered
        expect(interaktor4).to receive(:call!).once.with(context).ordered

        instance.call
      end
    end
  end
end
