RSpec.describe FlowMachine::ChangeCallback do
  subject(:callback) { described_class.new(:field, :method, if: :condition?) }

  specify { expect(callback.field).to eq(:field) }
  specify { expect(callback.method).to eq(:method) }
  specify { expect(callback.options).to eq({ if: :condition? }) }

  let(:object) { double(condition?: true) }
  before { allow(object).to receive(:run_workflow_method) { |m| object.send(m) } }

  context 'the field changes' do
    let(:changes) { { 'field' => [:old, :new] } }
    it 'calls the method' do
      expect(object).to receive(:method)
      callback.call(object, changes)
    end
  end

  context 'the field does not change' do
    let(:changes) { { 'other_field' => [:old, :new] } }
    it 'does not call the method' do
      expect(object).to receive(:method).never
      callback.call(object, changes)
    end
  end
end
