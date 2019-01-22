# frozen_string_literal: true

RSpec.describe FlowMachine::WorkflowState do
  class StateTestClass < described_class
    def self.state_name
      :test
    end

    def guard1?; end

    def guard2?; end

    def after_hook; end
  end

  class WorkflowTestClass
    include FlowMachine::Workflow
    def workflow_guard?; end

    def workflow_hook; end
  end

  let(:state_class) { Class.new(StateTestClass) }
  let(:workflow_class) { Class.new WorkflowTestClass }

  before do
    workflow_class.state state_class
  end

  let(:object) { double state: :test, changes: {}, save: true, new_record?: true }
  let(:workflow) { workflow_class.new(object) }

  describe "defining events" do
    context "a basic event" do
      subject(:state) { state_class.new(workflow) }

      before { state_class.event :event1 }

      it "defines the event on the object" do
        expect(state).to respond_to :event1
      end

      it "defines may_event1?" do
        expect(state).to respond_to :may_event1?
      end

      it "defines the bang event" do
        expect(state).to respond_to :event1!
      end
    end
  end

  describe "invalid transitions" do
    let(:state_class2) do
      Class.new(described_class) do
        def self.state_name
          :test2
        end
      end
    end

    before do
      state_class.event(:event1) { transition to: :test2 }
      workflow_class.refresh_state_methods!
      workflow_class.state state_class2
    end

    it "returns false when trying to transition to the current state" do
      expect(object).to receive(:state).and_return :test2
      expect(workflow.event1).to be false
    end

    it "sets an invalid_event error when trying to transition to the curent state" do
      expect(object).to receive(:state).and_return :test2
      workflow.event1
      expect(workflow.guard_errors).to eq([:invalid_event])
    end

    it "sets an invalid_event error when trying to may to the current state" do
      expect(object).to receive(:state).and_return :test2
      expect(workflow).not_to be_may_event1
      expect(workflow.guard_errors).to eq([:invalid_event])
    end
  end

  describe "guards" do
    subject(:state) { workflow.current_state }

    context "a single guard" do
      before { state_class.event(:event1, guard: :guard1?) {} }

      it "calls the guard" do
        expect(state).to receive(:guard1?).and_return true
        state.event1
      end

      describe "may?" do
        it "is able to transition if the guard returns true" do
          expect(state).to receive(:guard1?).and_return true
          expect(state.may_event1?).to be true
        end

        it "is not able to transition if the guard returns false" do
          expect(state).to receive(:guard1?).and_return false
          expect(state.may_event1?).to be false
        end
      end
    end

    context "the guard method is on the workflow instead" do
      before { state_class.event(:event1, guard: :workflow_guard?) {} }

      it "calls the guard" do
        expect(workflow).to receive(:workflow_guard?).and_return true
        state.event1
      end
    end

    context "the guard method is on the object" do
      before { state_class.event(:event1, guard: :object_guard?) {} }

      it "calls the guard" do
        expect(object).to receive(:object_guard?).and_return true
        state.event1
      end
    end

    context "multiple guards" do
      before do
        state_class.event(:event1, guard: %i[guard1? guard2?]) {}
        workflow_class.refresh_state_methods!
      end

      it "calls all the guards" do
        expect(state).to receive(:guard1?).and_return true
        expect(state).to receive(:guard2?).and_return true
        state.event1
      end

      context "one guard returns false" do
        before do
          expect(state).to receive(:guard1?).and_return false
          expect(state).to receive(:guard2?).and_return true
        end

        it "gets the guard errors on may_event" do
          workflow.may_event1?
          expect(workflow.guard_errors).to eq([:guard1?])
        end

        it "gets the guard errors on transition" do
          workflow.event1
          expect(workflow.guard_errors).to eq([:guard1?])
        end
      end
    end

    it "does not call the event block if the guard fails" do
      state_class.event(:event1, guard: [:guard1?]) { raise "Should not call block" }
      expect(state).to receive(:guard1?).and_return false
      state.event1
    end
  end

  describe "triggering workflow after_transition hook" do
    let(:state) { workflow.current_state }

    before do
      workflow_class.after_transition :workflow_hook

      state_class.event :event1, guard: :guard1? do
        transition to: :state2
      end

      workflow_class.refresh_state_methods!
    end

    it "calls the hook on transition" do
      # allow the transition, and make it think it's a different state
      expect(workflow).to receive(:current_state_name=).with("state2")
      expect(state).to receive(:==).and_return false

      expect(state).to receive(:guard1?).and_return(true)
      expect(workflow).to receive(:workflow_hook)
      workflow.event1
    end

    it "does not call the hook on failure" do
      expect(state).to receive(:guard1?).and_return(false)
      expect(workflow).not_to receive(:workflow_hook)
      workflow.event1
    end
  end

  describe "after transition hooks" do
    let(:state) { workflow.current_state }

    before do
      state_class.event :event1 do
        transition to: :state2, after: :after_hook
      end

      workflow_class.refresh_state_methods!

      expect(workflow).to receive(:current_state_name=).with("state2")
    end

    it "does not call the hook before saving" do
      expect(state).not_to receive(:after_hook)
      workflow.event1
    end

    it "calls the hook after saving the transition" do
      expect(state).to receive(:after_hook).once
      workflow.event1
      workflow.persist
    end
  end

  describe "on_enter" do
    let(:state) { state_class.new(workflow) }

    context "the method is on the workflow" do
      before { state_class.on_enter :workflow_hook }

      it "can call the method" do
        expect(workflow).to receive(:workflow_hook)
        state.fire_callbacks(:on_enter, {})
      end
    end
  end

  describe "on_exit" do
    let(:state) { state_class.new(workflow) }

    context "the method is on the workflow" do
      before { state_class.on_exit :workflow_hook }

      it "can call the method" do
        expect(workflow).to receive(:workflow_hook)
        state.fire_callbacks(:on_exit, {})
      end
    end
  end

  describe "after_enter" do
    let(:state) { state_class.new(workflow) }

    context "the method is on the workflow" do
      before { state_class.after_enter :workflow_hook }

      it "can call the method" do
        expect(workflow).to receive(:workflow_hook)
        state.fire_callbacks(:after_enter, {})
      end
    end

    context "the method is on the object" do
      before { state_class.after_enter :object_hook }

      it "can call the method" do
        expect(object).to receive(:object_hook)
        state.fire_callbacks(:after_enter, {})
      end
    end
  end

  describe "#run_workflow_method" do
    let(:state) { state_class.new(workflow) }

    context "nothing in the chain has the method" do
      it "raises a NoMethodError" do
        expect { state.run_workflow_method :some_method }.to raise_error(NoMethodError)
      end
    end

    context "the object defines the method" do
      before do
        allow(object).to receive(:some_method)
      end

      it "calls the method on object" do
        expect(object).to receive(:some_method)
        state.run_workflow_method :some_method
      end

      context "and the workflow defines the method" do
        before do
          workflow.singleton_class.send(:define_method, :some_method) {}
        end

        it "calls the method on workflow" do
          expect(workflow).to receive(:some_method)
          state.run_workflow_method :some_method
        end

        context "and the state defines the method" do
          before do
            state.singleton_class.send(:define_method, :some_method) {}
          end

          it "calls the method on the state" do
            expect(state).to receive(:some_method)
            state.run_workflow_method :some_method
          end
        end
      end
    end
  end
end
