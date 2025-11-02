module Interaktor
  RSpec.describe Context do
    describe ".build" do
      it "converts the given hash to a context" do
        context = described_class.build(foo: "bar")

        expect(context).to be_a(described_class)
        expect(context.foo).to eq("bar")
      end

      it "builds an empty context if no hash is given" do
        context = described_class.build

        expect(context).to be_a(described_class)
        expect(context.send(:table)).to eq({})
      end

      it "doesn't affect the original hash" do
        hash = {foo: "bar"}
        context = described_class.build(hash)

        expect(context).to be_a(described_class)
        expect {
          context.foo = "baz"
        }.not_to(change {
          hash[:foo]
        })
      end

      it "preserves an already built context" do
        context1 = described_class.build(foo: "bar")
        context2 = described_class.build(context1)

        expect(context2).to be_a(described_class)
        expect {
          context2.foo = "baz"
        }.to change {
          context1.foo
        }.from("bar").to("baz")
      end
    end

    describe "#success?" do
      let(:context) { described_class.build }

      it "is true by default" do
        expect(context.success?).to eq(true)
      end
    end

    describe "#failure?" do
      let(:context) { described_class.build }

      it "is false by default" do
        expect(context.failure?).to eq(false)
      end
    end

    describe "#fail!" do
      let(:context) { described_class.build(foo: "bar") }

      it "sets success to false" do
        expect {
          begin
            context.fail!
          rescue
            nil
          end
        }.to change(context, :success?).from(true).to(false)
      end

      it "sets failure to true" do
        expect {
          begin
            context.fail!
          rescue
            nil
          end
        }.to change(context, :failure?).from(false).to(true)
      end

      it "preserves failure" do
        begin
          context.fail!
        rescue
          nil
        end

        expect {
          begin
            context.fail!
          rescue
            nil
          end
        }.not_to change(context, :failure?)
      end

      it "preserves the context" do
        expect {
          begin
            context.fail!
          rescue
            nil
          end
        }.not_to change(context, :foo)
      end

      it "updates the context" do
        expect {
          begin
            context.fail!(foo: "baz")
          rescue
            nil
          end
        }.to change(context, :foo).from("bar").to("baz")
      end

      it "updates the context with a string key" do
        expect {
          begin
            context.fail!("foo" => "baz")
          rescue
            nil
          end
        }.to change(context, :foo).from("bar").to("baz")
      end

      it "raises failure" do
        expect {
          context.fail!
        }.to raise_error(Failure)
      end

      it "makes the context available from the failure" do
        context.fail!
      rescue Failure => e
        expect(e.context).to eq(context)
      end
    end

    describe "#called!" do
      let(:context) { described_class.build }
      let(:instance1) { instance_double(Interaktor) }
      let(:instance2) { instance_double(Interaktor) }

      it "appends to the internal list of called instances" do
        expect {
          context.called!(instance1)
          context.called!(instance2)
        }.to change(context, :_called).from([]).to([instance1, instance2])
      end
    end

    describe "#rollback!" do
      let(:context) { described_class.build }
      let(:instance1) { instance_double(Interaktor) }
      let(:instance2) { instance_double(Interaktor) }

      before do
        allow(context).to receive(:_called) { [instance1, instance2] }
      end

      it "rolls back each instance in reverse order" do
        expect(instance2).to receive(:rollback).once.with(no_args).ordered
        expect(instance1).to receive(:rollback).once.with(no_args).ordered

        context.rollback!
      end

      it "ignores subsequent attempts" do
        expect(instance2).to receive(:rollback).once
        expect(instance1).to receive(:rollback).once

        context.rollback!
        context.rollback!
      end
    end

    describe "#_called" do
      let(:context) { described_class.build }

      it "is empty by default" do
        expect(context._called).to eq([])
      end
    end
  end
end
