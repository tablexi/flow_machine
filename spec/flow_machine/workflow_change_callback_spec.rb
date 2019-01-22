# frozen_string_literal: true

RSpec.describe FlowMachine::ChangeCallback do
  subject(:callback) { described_class.new(:field, :method, if: :condition?) }

  before { allow(object).to receive(:run_workflow_method) { |m| object.send(m) } }

  let(:object) { double(condition?: true) }

  specify { expect(callback.field).to eq(:field) }
  specify { expect(callback.method).to eq(:method) }
  specify { expect(callback.options).to eq(if: :condition?) }

  context "the field changes" do
    let(:changes) { { "field" => %i[old new] } }

    it "calls the method" do
      expect(object).to receive(:method)
      callback.call(object, changes)
    end
  end

  context "the field does not change" do
    let(:changes) { { "other_field" => %i[old new] } }

    it "does not call the method" do
      expect(object).not_to receive(:method)
      callback.call(object, changes)
    end
  end
end
