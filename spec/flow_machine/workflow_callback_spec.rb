# frozen_string_literal: true

RSpec.describe FlowMachine::Callback do
  let(:object) { double }

  describe "callback with method" do
    let(:callback) { described_class.new(:some_method) }

    it "calls the method" do
      expect(object).to receive(:some_method)
      callback.call(object)
    end
  end

  describe "callback with block" do
    let(:callback) do
      described_class.new { some_method }
    end

    it "calls the method" do
      expect(object).to receive(:some_method)
      callback.call(object)
    end
  end

  describe "callback with if" do
    context "a single if" do
      let(:callback) { described_class.new(:some_method, if: :if_method?) }

      context "if method returns true" do
        before { allow(object).to receive(:if_method?).and_return true }

        it "calls the method" do
          expect(object).to receive(:some_method)
          callback.call(object)
        end
      end

      context "if method returns false" do
        before { allow(object).to receive(:if_method?).and_return false }

        it "does not call the method" do
          expect(object).not_to receive(:some_method)
          callback.call(object)
        end
      end
    end

    context "a lambda for if" do
      let(:callback) do
        described_class.new(:some_method, if: -> { if_method? })
      end

      it "calls the method when true" do
        allow(object).to receive(:if_method?).and_return true
        expect(object).to receive(:some_method)
        callback.call(object)
      end

      it "does not call the method when false" do
        allow(object).to receive(:if_method?).and_return false
        expect(object).not_to receive(:some_method)
        callback.call(object)
      end
    end

    context "an array of ifs" do
      let(:callback) { described_class.new(:some_method, if: %i[if_method? if2?]) }

      context "both return true" do
        before do
          allow(object).to receive(:if_method?).and_return true
          allow(object).to receive(:if2?).and_return true
        end

        it "calls the method" do
          expect(object).to receive(:some_method)
          callback.call(object)
        end
      end

      context "one returns false" do
        before do
          allow(object).to receive(:if_method?).and_return true
          allow(object).to receive(:if2?).and_return false
        end

        it "does not call the method" do
          expect(object).not_to receive(:some_method)
          callback.call(object)
        end
      end
    end
  end

  describe "callback with unless" do
    context "a single if" do
      let(:callback) { described_class.new(:some_method, unless: :unless_method?) }

      context "unless method returns false" do
        before { allow(object).to receive(:unless_method?).and_return false }

        it "calls the method" do
          expect(object).to receive(:some_method)
          callback.call(object)
        end
      end

      context "unless method returns true" do
        before { allow(object).to receive(:unless_method?).and_return true }

        it "does not call the method" do
          expect(object).not_to receive(:some_method)
          callback.call(object)
        end
      end
    end

    context "a lambda for unless" do
      let(:callback) do
        described_class.new(:some_method, unless: -> { unless_method? })
      end

      it "calls the method when false" do
        allow(object).to receive(:unless_method?).and_return false
        expect(object).to receive(:some_method)
        callback.call(object)
      end

      it "does not call the method when true" do
        allow(object).to receive(:unless_method?).and_return true
        expect(object).not_to receive(:some_method)
        callback.call(object)
      end
    end
  end
end
