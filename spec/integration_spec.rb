# rubocop:disable RSpec/InstanceVariable
# rubocop:disable RSpec/MultipleMemoizedHelpers
# rubocop:disable RSpec/ScatteredSetup
# rubocop:disable Style/DocumentationMethod

RSpec.describe "Integration" do
  # rubocop:disable Style/AsciiComments
  #
  # organizer
  #  ├─ organizer2
  #  │   ├─ interaktor2a
  #  │   ├─ interaktor2b
  #  │   └─ interaktor2c
  #  ├─ interaktor3
  #  ├─ organizer4
  #  │   ├─ interaktor4a
  #  │   ├─ interaktor4b
  #  │   └─ interaktor4c
  #  └─ interaktor5
  #
  # rubocop:enable Style/AsciiComments

  let(:organizer) {
    interaktors = [organizer2, interaktor3, organizer4, interaktor5]

    FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
      organize(interaktors)

      around do |interaktor|
        @context.steps << :around_before
        interaktor.call
        @context.steps << :around_after
      end

      before do
        @context.steps << :before
      end

      after do
        @context.steps << :after
      end
    end
  }

  let(:organizer2) {
    interaktors = [interaktor2a, interaktor2b, interaktor2c]

    FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
      organize(interaktors)

      around do |interaktor|
        @context.steps << :around_before2
        interaktor.call
        @context.steps << :around_after2
      end

      before do
        @context.steps << :before2
      end

      after do
        @context.steps << :after2
      end
    end
  }

  let(:interaktor2a) {
    FakeInteraktor.build_interaktor do
      around do |interaktor|
        @context.steps << :around_before2a
        interaktor.call
        @context.steps << :around_after2a
      end

      before do
        @context.steps << :before2a
      end

      after do
        @context.steps << :after2a
      end

      def call
        @context.steps << :call2a
      end

      def rollback
        @context.steps << :rollback2a
      end
    end
  }

  let(:interaktor2b) {
    FakeInteraktor.build_interaktor do
      around do |interaktor|
        @context.steps << :around_before2b
        interaktor.call
        @context.steps << :around_after2b
      end

      before do
        @context.steps << :before2b
      end

      after do
        @context.steps << :after2b
      end

      def call
        @context.steps << :call2b
      end

      def rollback
        @context.steps << :rollback2b
      end
    end
  }

  let(:interaktor2c) {
    FakeInteraktor.build_interaktor do
      around do |interaktor|
        @context.steps << :around_before2c
        interaktor.call
        @context.steps << :around_after2c
      end

      before do
        @context.steps << :before2c
      end

      after do
        @context.steps << :after2c
      end

      def call
        @context.steps << :call2c
      end

      def rollback
        @context.steps << :rollback2c
      end
    end
  }

  let(:interaktor3) {
    FakeInteraktor.build_interaktor do
      around do |interaktor|
        @context.steps << :around_before3
        interaktor.call
        @context.steps << :around_after3
      end

      before do
        @context.steps << :before3
      end

      after do
        @context.steps << :after3
      end

      def call
        @context.steps << :call3
      end

      def rollback
        @context.steps << :rollback3
      end
    end
  }

  let(:organizer4) {
    interaktors = [interaktor4a, interaktor4b, interaktor4c]

    FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
      organize(interaktors)

      around do |interaktor|
        @context.steps << :around_before4
        interaktor.call
        @context.steps << :around_after4
      end

      before do
        @context.steps << :before4
      end

      after do
        @context.steps << :after4
      end
    end
  }

  let(:interaktor4a) {
    FakeInteraktor.build_interaktor do
      around do |interaktor|
        @context.steps << :around_before4a
        interaktor.call
        @context.steps << :around_after4a
      end

      before do
        @context.steps << :before4a
      end

      after do
        @context.steps << :after4a
      end

      def call
        @context.steps << :call4a
      end

      def rollback
        @context.steps << :rollback4a
      end
    end
  }

  let(:interaktor4b) {
    FakeInteraktor.build_interaktor do
      around do |interaktor|
        @context.steps << :around_before4b
        interaktor.call
        @context.steps << :around_after4b
      end

      before do
        @context.steps << :before4b
      end

      after do
        @context.steps << :after4b
      end

      def call
        @context.steps << :call4b
      end

      def rollback
        @context.steps << :rollback4b
      end
    end
  }

  let(:interaktor4c) {
    FakeInteraktor.build_interaktor do
      around do |interaktor|
        @context.steps << :around_before4c
        interaktor.call
        @context.steps << :around_after4c
      end

      before do
        @context.steps << :before4c
      end

      after do
        @context.steps << :after4c
      end

      def call
        @context.steps << :call4c
      end

      def rollback
        @context.steps << :rollback4c
      end
    end
  }

  let(:interaktor5) {
    FakeInteraktor.build_interaktor do
      around do |interaktor|
        @context.steps << :around_before5
        interaktor.call
        @context.steps << :around_after5
      end

      before do
        @context.steps << :before5
      end

      after do
        @context.steps << :after5
      end

      def call
        @context.steps << :call5
      end

      def rollback
        @context.steps << :rollback5
      end
    end
  }

  let(:context) { Interaktor::Context.new(steps: []) }

  context "when successful" do
    it "calls and runs hooks in the proper sequence" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b, :call4b, :after4b, :around_after4b,
        :around_before4c, :before4c, :call4c, :after4c, :around_after4c,
        :after4, :around_after4,
        :around_before5, :before5, :call5, :after5, :around_after5,
        :after, :around_after
      ])
    end
  end

  context "when an around hook fails early" do
    let(:organizer) {
      interaktors = [organizer2, interaktor3, organizer4, interaktor5]

      FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
        organize(interaktors)

        around do |interaktor|
          @context.fail!
          @context.steps << :around_before
          interaktor.call
          @context.steps << :around_after
        end

        before do
          @context.fail!
          @context.steps << :before
        end

        after do
          @context.steps << :after
        end
      end
    }

    it "aborts" do
      expect {
        organizer.call(context)
      }.not_to change(context, :steps)
    end
  end

  context "when an around hook errors early" do
    let(:organizer) {
      interaktors = [organizer2, interaktor3, organizer4, interaktor5]

      FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
        organize(interaktors)

        around do |interaktor|
          unexpected_error!
          @context.steps << :around_before
          interaktor.call
          @context.steps << :around_after
        end

        before do
          @context.fail!
          @context.steps << :before
        end

        after do
          @context.steps << :after
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "aborts" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.not_to change(context, :steps)
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a before hook fails" do
    let(:organizer) {
      interaktors = [organizer2, interaktor3, organizer4, interaktor5]

      FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
        organize(interaktors)

        around do |interaktor|
          @context.steps << :around_before
          interaktor.call
          @context.steps << :around_after
        end

        before do
          @context.fail!
          @context.steps << :before
        end

        after do
          @context.steps << :after
        end
      end
    }

    it "aborts" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before
      ])
    end
  end

  context "when a before hook errors" do
    let(:organizer) {
      interaktors = [organizer2, interaktor3, organizer4, interaktor5]

      FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
        organize(interaktors)

        around do |interaktor|
          @context.steps << :around_before
          interaktor.call
          @context.steps << :around_after
        end

        before do
          unexpected_error!
          @context.steps << :before
        end

        after do
          @context.steps << :after
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "aborts" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when an after hook fails" do
    let(:organizer) {
      interaktors = [organizer2, interaktor3, organizer4, interaktor5]

      FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
        organize(interaktors)

        around do |interaktor|
          @context.steps << :around_before
          interaktor.call
          @context.steps << :around_after
        end

        before do
          @context.steps << :before
        end

        after do
          @context.fail!
          @context.steps << :after
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b, :call4b, :after4b, :around_after4b,
        :around_before4c, :before4c, :call4c, :after4c, :around_after4c,
        :after4, :around_after4,
        :around_before5, :before5, :call5, :after5, :around_after5,
        :rollback5,
        :rollback4c,
        :rollback4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when an after hook errors" do
    let(:organizer) {
      interaktors = [organizer2, interaktor3, organizer4, interaktor5]

      FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
        organize(interaktors)

        around do |interaktor|
          @context.steps << :around_before
          interaktor.call
          @context.steps << :around_after
        end

        before do
          @context.steps << :before
        end

        after do
          unexpected_error!
          @context.steps << :after
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b, :call4b, :after4b, :around_after4b,
        :around_before4c, :before4c, :call4c, :after4c, :around_after4c,
        :after4, :around_after4,
        :around_before5, :before5, :call5, :after5, :around_after5,
        :rollback5,
        :rollback4c,
        :rollback4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when an around hook fails late" do
    let(:organizer) {
      interaktors = [organizer2, interaktor3, organizer4, interaktor5]

      FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
        organize(interaktors)

        around do |interaktor|
          @context.steps << :around_before
          interaktor.call
          @context.fail!
          @context.steps << :around_after
        end

        before do
          @context.steps << :before
        end

        after do
          @context.steps << :after
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b, :call4b, :after4b, :around_after4b,
        :around_before4c, :before4c, :call4c, :after4c, :around_after4c,
        :after4, :around_after4,
        :around_before5, :before5, :call5, :after5, :around_after5,
        :after,
        :rollback5,
        :rollback4c,
        :rollback4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when an around hook errors late" do
    let(:organizer) {
      interaktors = [organizer2, interaktor3, organizer4, interaktor5]

      FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
        organize(interaktors)

        around do |interaktor|
          @context.steps << :around_before
          interaktor.call
          unexpected_error!
          @context.steps << :around_after
        end

        before do
          @context.steps << :before
        end

        after do
          @context.steps << :after
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b, :call4b, :after4b, :around_after4b,
        :around_before4c, :before4c, :call4c, :after4c, :around_after4c,
        :after4, :around_after4,
        :around_before5, :before5, :call5, :after5, :around_after5,
        :after,
        :rollback5,
        :rollback4c,
        :rollback4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a nested around hook fails early" do
    let(:interaktor3) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.fail!
          @context.steps << :around_before3
          interaktor.call
          @context.steps << :around_after3
        end

        before do
          @context.steps << :before3
        end

        after do
          @context.steps << :after3
        end

        def call
          @context.steps << :call3
        end

        def rollback
          @context.steps << :rollback3
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when a nested around hook errors early" do
    let(:interaktor3) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          unexpected_error!
          @context.steps << :around_before3
          interaktor.call
          @context.steps << :around_after3
        end

        before do
          @context.steps << :before3
        end

        after do
          @context.steps << :after3
        end

        def call
          @context.steps << :call3
        end

        def rollback
          @context.steps << :rollback3
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a nested before hook fails" do
    let(:interaktor3) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before3
          interaktor.call
          @context.steps << :around_after3
        end

        before do
          @context.fail!
          @context.steps << :before3
        end

        after do
          @context.steps << :after3
        end

        def call
          @context.steps << :call3
        end

        def rollback
          @context.steps << :rollback3
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when a nested before hook errors" do
    let(:interaktor3) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before3
          interaktor.call
          @context.steps << :around_after3
        end

        before do
          unexpected_error!
          @context.steps << :before3
        end

        after do
          @context.steps << :after3
        end

        def call
          @context.steps << :call3
        end

        def rollback
          @context.steps << :rollback3
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a nested call fails" do
    let(:interaktor3) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before3
          interaktor.call
          @context.steps << :around_after3
        end

        before do
          @context.steps << :before3
        end

        after do
          @context.steps << :after3
        end

        def call
          @context.fail!
          @context.steps << :call3
        end

        def rollback
          @context.steps << :rollback3
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when a nested call errors" do
    let(:interaktor3) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before3
          interaktor.call
          @context.steps << :around_after3
        end

        before do
          @context.steps << :before3
        end

        after do
          @context.steps << :after3
        end

        def call
          unexpected_error!
          @context.steps << :call3
        end

        def rollback
          @context.steps << :rollback3
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a nested after hook fails" do
    let(:interaktor3) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before3
          interaktor.call
          @context.steps << :around_after3
        end

        before do
          @context.steps << :before3
        end

        after do
          @context.fail!
          @context.steps << :after3
        end

        def call
          @context.steps << :call3
        end

        def rollback
          @context.steps << :rollback3
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when a nested after hook errors" do
    let(:interaktor3) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before3
          interaktor.call
          @context.steps << :around_after3
        end

        before do
          @context.steps << :before3
        end

        after do
          unexpected_error!
          @context.steps << :after3
        end

        def call
          @context.steps << :call3
        end

        def rollback
          @context.steps << :rollback3
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a nested around hook fails late" do
    let(:interaktor3) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before3
          interaktor.call
          @context.fail!
          @context.steps << :around_after3
        end

        before do
          @context.steps << :before3
        end

        after do
          @context.steps << :after3
        end

        def call
          @context.steps << :call3
        end

        def rollback
          @context.steps << :rollback3
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when a nested around hook errors late" do
    let(:interaktor3) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before3
          interaktor.call
          unexpected_error!
          @context.steps << :around_after3
        end

        before do
          @context.steps << :before3
        end

        after do
          @context.steps << :after3
        end

        def call
          @context.steps << :call3
        end

        def rollback
          @context.steps << :rollback3
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a deeply nested around hook fails early" do
    let(:interaktor4b) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.fail!
          @context.steps << :around_before4b
          interaktor.call
          @context.steps << :around_after4b
        end

        before do
          @context.steps << :before4b
        end

        after do
          @context.steps << :after4b
        end

        def call
          @context.steps << :call4b
        end

        def rollback
          @context.steps << :rollback4b
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when a deeply nested around hook errors early" do
    let(:interaktor4b) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          unexpected_error!
          @context.steps << :around_before4b
          interaktor.call
          @context.steps << :around_after4b
        end

        before do
          @context.steps << :before4b
        end

        after do
          @context.steps << :after4b
        end

        def call
          @context.steps << :call4b
        end

        def rollback
          @context.steps << :rollback4b
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a deeply nested before hook fails" do
    let(:interaktor4b) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before4b
          interaktor.call
          @context.steps << :around_after4b
        end

        before do
          @context.fail!
          @context.steps << :before4b
        end

        after do
          @context.steps << :after4b
        end

        def call
          @context.steps << :call4b
        end

        def rollback
          @context.steps << :rollback4b
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when a deeply nested before hook errors" do
    let(:interaktor4b) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before4b
          interaktor.call
          @context.steps << :around_after4b
        end

        before do
          unexpected_error!
          @context.steps << :before4b
        end

        after do
          @context.steps << :after4b
        end

        def call
          @context.steps << :call4b
        end

        def rollback
          @context.steps << :rollback4b
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a deeply nested call fails" do
    let(:interaktor4b) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before4b
          interaktor.call
          @context.steps << :around_after4b
        end

        before do
          @context.steps << :before4b
        end

        after do
          @context.steps << :after4b
        end

        def call
          @context.fail!
          @context.steps << :call4b
        end

        def rollback
          @context.steps << :rollback4b
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when a deeply nested call errors" do
    let(:interaktor4b) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before4b
          interaktor.call
          @context.steps << :around_after4b
        end

        before do
          @context.steps << :before4b
        end

        after do
          @context.steps << :after4b
        end

        def call
          unexpected_error!
          @context.steps << :call4b
        end

        def rollback
          @context.steps << :rollback4b
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a deeply nested after hook fails" do
    let(:interaktor4b) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before4b
          interaktor.call
          @context.steps << :around_after4b
        end

        before do
          @context.steps << :before4b
        end

        after do
          @context.fail!
          @context.steps << :after4b
        end

        def call
          @context.steps << :call4b
        end

        def rollback
          @context.steps << :rollback4b
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b, :call4b,
        :rollback4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when a deeply nested after hook errors" do
    let(:interaktor4b) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before4b
          interaktor.call
          @context.steps << :around_after4b
        end

        before do
          @context.steps << :before4b
        end

        after do
          unexpected_error!
          @context.steps << :after4b
        end

        def call
          @context.steps << :call4b
        end

        def rollback
          @context.steps << :rollback4b
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b, :call4b,
        :rollback4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when a deeply nested around hook fails late" do
    let(:interaktor4b) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before4b
          interaktor.call
          @context.fail!
          @context.steps << :around_after4b
        end

        before do
          @context.steps << :before4b
        end

        after do
          @context.steps << :after4b
        end

        def call
          @context.steps << :call4b
        end

        def rollback
          @context.steps << :rollback4b
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b, :call4b, :after4b,
        :rollback4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end
  end

  context "when a deeply nested around hook errors late" do
    let(:interaktor4b) {
      FakeInteraktor.build_interaktor do
        around do |interaktor|
          @context.steps << :around_before4b
          interaktor.call
          unexpected_error!
          @context.steps << :around_after4b
        end

        before do
          @context.steps << :before4b
        end

        after do
          @context.steps << :after4b
        end

        def call
          @context.steps << :call4b
        end

        def rollback
          @context.steps << :rollback4b
        end

        def unexpected_error!
          raise "foo"
        end
      end
    }

    it "rolls back successfully called interaktors and the failed interaktor" do
      expect {
        begin
          organizer.call(context)
        rescue
          nil
        end
      }.to change(context, :steps).from([]).to([
        :around_before, :before,
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b, :call4b, :after4b,
        :rollback4b,
        :rollback4a,
        :rollback3,
        :rollback2c,
        :rollback2b,
        :rollback2a
      ])
    end

    it "raises the error" do
      expect {
        organizer.call(context)
      }.to raise_error("foo")
    end
  end

  context "when there are multiple organize calls" do
    it "runs all passed interaktors in correct order" do
      # organizer = build_organizer(organize: [organizer2, interaktor3])
      interaktors = [organizer2, interaktor3]

      organizer = FakeInteraktor.build_interaktor(type: Interaktor::Organizer) do
        organize(interaktors)

        def unexpected_error!
          raise "foo"
        end
      end

      organizer.organize(organizer4, interaktor5)

      expect {
        organizer.call(context)
      }.to change(context, :steps).from([]).to([
        :around_before2, :before2,
        :around_before2a, :before2a, :call2a, :after2a, :around_after2a,
        :around_before2b, :before2b, :call2b, :after2b, :around_after2b,
        :around_before2c, :before2c, :call2c, :after2c, :around_after2c,
        :after2, :around_after2,
        :around_before3, :before3, :call3, :after3, :around_after3,
        :around_before4, :before4,
        :around_before4a, :before4a, :call4a, :after4a, :around_after4a,
        :around_before4b, :before4b, :call4b, :after4b, :around_after4b,
        :around_before4c, :before4c, :call4c, :after4c, :around_after4c,
        :after4, :around_after4,
        :around_before5, :before5, :call5, :after5, :around_after5
      ])
    end
  end
end

# rubocop:enable RSpec/InstanceVariable
# rubocop:enable RSpec/MultipleMemoizedHelpers
# rubocop:enable RSpec/ScatteredSetup
# rubocop:enable Style/DocumentationMethod
