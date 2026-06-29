RSpec.describe Interaktor::Failure do
  describe "#message" do
    it "builds a message from the failure attributes" do
      interaktor = FakeInteraktor.build_interaktor do
        failure do
          attribute :error
          attribute :code
        end

        def call
          fail!(error: "not found", code: 404)
        end
      end

      expect {
        interaktor.call!
      }.to raise_error(described_class, 'error: "not found", code: 404')
    end

    it "falls back to the default message when there are no failure attributes" do
      interaktor = FakeInteraktor.build_interaktor do
        def call
          fail!
        end
      end

      expect {
        interaktor.call!
      }.to raise_error(described_class, described_class.name)
    end

    it "falls back to the default message when the interaction is absent" do
      expect(described_class.new.message).to eq described_class.name
    end
  end
end
