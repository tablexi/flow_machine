require 'ostruct'

RSpec.describe FlowMachine::Workflow do
  class Test1State < FlowMachine::WorkflowState
    def state_method; end
  end

  class Test2State < FlowMachine::WorkflowState
    def state_method; end
  end

  class TestWorkflow
    include FlowMachine::Workflow
    state Test1State
    state Test2State
    before_save :before_save_callback
    after_save :after_save_callback
    after_transition :after_transition_callback
    def workflow_method; end
    def before_save_callback; end
    def after_save_callback; end
    def after_transition_callback; end
  end

  describe 'state_names' do
    it 'has the state names' do
      expect(TestWorkflow.state_names).to eq(['test1', 'test2'])
    end

    it 'has the states in a hash keyed by names' do
      expect(TestWorkflow.states).to eq({ test1: Test1State, test2: Test2State })
    end
  end

  describe 'reading initial state' do
    subject(:workflow) { TestWorkflow.new(object) }
    context 'default state field' do
      let(:object) { double(state: :test1) }
      it 'has the state' do
        expect(workflow.current_state_name).to eq(:test1)
      end
    end

    context 'with a different state field on the object' do
      before { TestWorkflow.send(:state_attribute, :status) }
      # return to default
      after { TestWorkflow.send(:state_attribute, :state) }

      let(:object) { double(status: :test2) }
      it 'has the state' do
        expect(workflow.current_state_name).to eq(:test2)
      end
    end
  end

  describe '#transition' do
    subject(:workflow) { TestWorkflow.new(object) }
    let(:object) { double(state: :test1) }

    it 'errors on an invalid state' do
      expect { workflow.transition to: :invalid }.to raise_error(ArgumentError)
    end

    it 'changes the state of the object' do
      expect(object).to receive(:state=).with('test2')
      workflow.transition to: :test2
    end

    it 'leaves the state if transitions to itself' do
      workflow.transition
      expect(workflow.current_state_name).to eq(:test1)
      expect(object.state).to eq(:test1)
    end
  end

  describe 'transition :after hooks' do
    subject(:workflow) { TestWorkflow.new(object) }
    let(:object) { OpenStruct.new(state: :test1, changes: {}, save: true, object_method: true) }

    it 'does not call the :after hook before saving' do
      expect(workflow).not_to receive(:workflow_method)
      workflow.transition to: :test2, after: :workflow_method
    end

    it 'does not calls the :after hook on failure' do
      expect(workflow).not_to receive(:workflow_method)
      workflow.transition to: :test1
      workflow.save
    end

    it 'calls the :after hook on a state method' do
      expect_any_instance_of(Test1State).to receive(:state_method)
      expect_any_instance_of(Test2State).not_to receive(:state_method)
      workflow.transition to: :test2, after: :state_method
      workflow.save
    end

    it 'calls the :after hook on a workflow method' do
      expect(workflow).to receive(:workflow_method)
      workflow.transition to: :test2, after: :workflow_method
      workflow.save
    end

    it 'calls the :after hook on an object method' do
      expect(object).to receive(:object_method)
      workflow.transition to: :test2, after: :object_method
      workflow.save
    end

    it 'allows a lambda' do
      expect_any_instance_of(Test1State).to receive(:state_method)
      workflow.transition to: :test2, after: ->{ state_method }
      workflow.save
    end

    describe 'after_transition hook' do
      it 'calls the hook on transition' do
        expect(workflow).to receive(:after_transition_callback)
        workflow.transition to: :test2
      end

      it 'does not call for invalid states' do
        expect(workflow).not_to receive(:after_transition_callback)
        expect { workflow.transition to: :invalid_state }.to raise_error(ArgumentError)
      end

      it 'does not call for ending in the same state' do
        expect(workflow).not_to receive(:after_transition_callback)
        workflow.transition to: :test1
      end
    end
  end

  describe '#persist' do
    subject(:workflow) { TestWorkflow.new(object) }
    let(:object) { OpenStruct.new(state: :test1, changes: {}, save: true) }

    context 'success' do
      it 'saves the object' do
        expect(workflow.persist).to be true
      end

      it 'runs before and after_change hooks' do
        expect(workflow.current_state).to receive(:fire_callbacks).with(:before_change, {})
        expect(workflow.current_state).to receive(:fire_callbacks).with(:after_change, {})
        expect(workflow.persist).to be true
      end

      it "runs after_enter hooks if it's in a new state" do
        allow(object).to receive(:changes).and_return({'state' => ['test1', 'test2']})
        expect(workflow.current_state).to receive(:fire_callbacks).with(:before_change, { 'state' => ['test1', 'test2'] })
        expect(workflow.current_state).to receive(:fire_callbacks).with(:after_change, { 'state' => ['test1', 'test2'] })
        expect(workflow.current_state).to receive(:fire_callbacks).with(:after_enter, { 'state' => ['test1', 'test2'] })
        expect(workflow.persist).to be true
      end

      it 'runs the before_save callback' do
        expect(workflow).to receive(:before_save_callback)
        workflow.persist
      end

      it 'runs the after_save callback' do
        expect(workflow).to receive(:after_save_callback)
        workflow.persist
      end
    end

    context 'failure' do
      before do
        expect(object).to receive(:save).and_return false
      end

      it 'does not save the object' do
        expect(workflow.persist).to be false
      end

      it 'runs the before_change callback' do
        expect(workflow.current_state).to receive(:fire_callbacks).with(:before_change, {})
        expect(workflow.persist).to be false
      end

      it 'runs the before_save callback' do
        expect(workflow).to receive(:before_save_callback)
        workflow.persist
      end

      it 'does not run the after_save callback' do
        expect(workflow).to_not receive(:after_save_callback)
        workflow.persist
      end

      it 'reverts to the old state' do
        expect(workflow).to be_test1
        workflow.transition to: :test2
        expect(workflow).to be_test2
        workflow.persist
        expect(workflow).to be_test1
      end
    end
  end
end
