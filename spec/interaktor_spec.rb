RSpec.describe Interaktor do
  let(:interaktor) { FakeInteractor.build_interaktor("AnInteraktor") }

  it_behaves_like "lint"
end
