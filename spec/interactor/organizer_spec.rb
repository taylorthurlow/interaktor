module Interaktor
  describe Organizer do
    let(:organizer) { Class.new.send(:include, Organizer) }

    include_examples "lint"

    describe ".organize" do
      let(:interaktor2) { double(:interaktor2) }
      let(:interaktor3) { double(:interaktor3) }

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
        interaktor4 = double(:interaktor4)
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
      let(:instance) { organizer.new }
      let(:context) { double(:context) }
      let(:interaktor2) { double(:interaktor2) }
      let(:interaktor3) { double(:interaktor3) }
      let(:interaktor4) { double(:interaktor4) }

      before do
        allow(instance).to receive(:context) { context }
        allow(organizer).to receive(:organized) {
          [interaktor2, interaktor3, interaktor4]
        }
      end

      it "calls each interaktor in order with the context" do
        expect(interaktor2).to receive(:call!).once.with(context).ordered
        expect(interaktor3).to receive(:call!).once.with(context).ordered
        expect(interaktor4).to receive(:call!).once.with(context).ordered

        instance.call
      end
    end
  end
end
