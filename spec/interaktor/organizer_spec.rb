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

      expect(interaktor1).to receive(:call).once.ordered.and_call_original
      expect(interaktor2).to receive(:call).once.ordered.and_call_original

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

      expect(interaktor1).to receive(:call).once.ordered.and_call_original
      expect(interaktor2).to receive(:call).once.ordered.and_call_original

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

      expect(interaktor1).to receive(:call).once.ordered.and_call_original
      expect(interaktor2).to receive(:call).once.ordered.and_call_original

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

      expect(interaktor1).to receive(:call).once.ordered.and_call_original
      expect(interaktor2).to receive(:call).once.ordered.and_call_original

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

    it "raises an exception when an organized interaktor calls #success! in a hook" do
      organizer = FakeInteraktor.build_interaktor(type: described_class)
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
        before { success! }
      end

      allow(organizer).to receive(:organized).and_return([interaktor1])

      expect {
        organizer.call
      }.to raise_error(Interaktor::Error::SuccessInHookError) { |error|
        expect(error.interaktor).to be interaktor1
      }
    end

    context "when an organized interaktor fails" do
      it "fails without attributes and doesn't call the later interaktors when the organizer declares no failure attributes" do
        organizer = FakeInteraktor.build_interaktor(type: described_class)
        interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
          failure { attribute :reason }

          def call
            fail!(reason: :nope)
          end
        end
        interaktor2 = FakeInteraktor.build_interaktor("Interaktor2")

        allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2])

        expect(interaktor2).not_to receive(:call)

        result = organizer.call

        expect(result.failure?).to be true
        expect(result.failure_object).to be nil
      end

      it "fails with the attributes the organizer builds from the failed interaction" do
        organizer = FakeInteraktor.build_interaktor(type: described_class) do
          failure do
            attribute :reason
            validates :reason, inclusion: [:interaktor2_failed]

            attribute :detail
          end

          def failure_attributes_from(interaction)
            case interaction
            when Interaktor2::Interaction
              {reason: :interaktor2_failed, detail: interaction.message}
            end
          end
        end
        interaktor1 = FakeInteraktor.build_interaktor("Interaktor1")
        interaktor2 = FakeInteraktor.build_interaktor("Interaktor2") do
          failure { attribute :message }

          def call
            fail!(message: "it broke")
          end
        end

        allow(organizer).to receive(:organized).and_return([interaktor1, interaktor2])

        result = organizer.call

        expect(result.failure?).to be true
        expect(result.reason).to eq :interaktor2_failed
        expect(result.detail).to eq "it broke"
      end

      it "raises Interaktor::Failure for the organizer interaction from .call!" do
        organizer = FakeInteraktor.build_interaktor(type: described_class) do
          failure { attribute :reason }

          def failure_attributes_from(interaction)
            {reason: :interaktor1_failed}
          end
        end
        interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
          def call
            fail!
          end
        end

        allow(organizer).to receive(:organized).and_return([interaktor1])

        expect {
          organizer.call!
        }.to raise_error(Interaktor::Failure) { |error|
          expect(error.interaction).to be_an organizer::Interaction
          expect(error.interaction.reason).to eq :interaktor1_failed
        }
      end

      it "raises when the failure attributes that the organizer builds aren't valid" do
        organizer = FakeInteraktor.build_interaktor(type: described_class) do
          failure do
            attribute :reason
            validates :reason, presence: true
          end

          def failure_attributes_from(interaction)
            nil
          end
        end
        interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
          def call
            fail!
          end
        end

        allow(organizer).to receive(:organized).and_return([interaktor1])

        expect {
          organizer.call
        }.to raise_error(Interaktor::Error::AttributeValidationError) { |error|
          expect(error.interaktor).to be_an organizer
          expect(error.validation_errors).to eq(reason: ["can't be blank"])
        }
      end

      it "passes the failure of a nested organizer to the outer organizer" do
        inner_organizer = FakeInteraktor.build_interaktor("InnerOrganizer", type: described_class) do
          failure { attribute :inner_reason }

          def failure_attributes_from(interaction)
            {inner_reason: :interaktor1_failed}
          end
        end
        outer_organizer = FakeInteraktor.build_interaktor("OuterOrganizer", type: described_class) do
          failure { attribute :outer_reason }

          def failure_attributes_from(interaction)
            case interaction
            when InnerOrganizer::Interaction
              {outer_reason: :"inner_#{interaction.inner_reason}"}
            end
          end
        end
        interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
          def call
            fail!
          end
        end

        allow(inner_organizer).to receive(:organized).and_return([interaktor1])
        allow(outer_organizer).to receive(:organized).and_return([inner_organizer])

        result = outer_organizer.call

        expect(result.outer_reason).to eq :inner_interaktor1_failed
      end

      it "raises the failure of an interaktor that an organized interaktor calls with .call!" do
        organizer = FakeInteraktor.build_interaktor(type: described_class) do
          failure { attribute :reason }

          def failure_attributes_from(interaction)
            {reason: :interaktor1_failed}
          end
        end
        inner_interaktor = FakeInteraktor.build_interaktor("InnerInteraktor") do
          define_method(:call) { fail! }
        end
        interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
          define_method(:call) { inner_interaktor.call! }
        end

        allow(organizer).to receive(:organized).and_return([interaktor1])

        expect {
          organizer.call
        }.to raise_error(Interaktor::Failure) { |error|
          expect(error.interaction).to be_an inner_interaktor::Interaction
        }
      end

      it "raises the failure of a second instance of an organized interaktor that it calls with .call!" do
        organizer = FakeInteraktor.build_interaktor(type: described_class) do
          input { attribute :depth }

          failure { attribute :reason }

          def failure_attributes_from(interaction)
            {reason: :interaktor1_failed}
          end
        end
        interaktor1 = FakeInteraktor.build_interaktor("Interaktor1") do
          input { attribute :depth }

          def call
            if depth == 0
              self.class.call!(depth: 1)
            else
              fail!
            end
          end
        end

        allow(organizer).to receive(:organized).and_return([interaktor1])

        expect {
          organizer.call(depth: 0)
        }.to raise_error(Interaktor::Failure) { |error|
          expect(error.interaction).to be_an interaktor1::Interaction
        }
      end
    end

    it "raises an exception if the organizer declares failure attributes but doesn't build them" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) do
        failure { attribute :reason }
      end
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1")

      allow(organizer).to receive(:organized).and_return([interaktor1])

      expect {
        organizer.call
      }.to raise_error(Interaktor::Error::InvalidOrganizerFailureDefinitionError) { |error|
        expect(error.interaktor).to be organizer
      }
    end

    it "raises an exception if the organizer builds failure attributes but doesn't declare them" do
      organizer = FakeInteraktor.build_interaktor(type: described_class) do
        def failure_attributes_from(interaction)
          {}
        end
      end
      interaktor1 = FakeInteraktor.build_interaktor("Interaktor1")

      allow(organizer).to receive(:organized).and_return([interaktor1])

      expect {
        organizer.call
      }.to raise_error(Interaktor::Error::InvalidOrganizerFailureDefinitionError) { |error|
        expect(error.interaktor).to be organizer
      }
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
