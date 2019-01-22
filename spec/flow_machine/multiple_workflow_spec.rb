# frozen_string_literal: true

RSpec.describe FlowMachine::Workflow do
  let(:state_class1) do
    Class.new(FlowMachine::WorkflowState) do
      def self.state_name
        :state1
      end
      event :event1
    end
  end

  let(:state_class2) do
    Class.new(FlowMachine::WorkflowState) do
      def self.state_name
        :state2
      end
      event :event2
    end
  end

  let(:workflow_class1) { Class.new }
  let(:workflow_class2) { Class.new }

  before do
    workflow_class1.include described_class
    workflow_class2.include described_class
    workflow_class1.state state_class1
    workflow_class2.state state_class2
  end

  context "class1" do
    subject { workflow_class1.new(double) }

    it { is_expected.to respond_to "event1" }
    it { is_expected.not_to respond_to "event2" }
  end

  context "class2" do
    subject { workflow_class2.new(double) }

    it { is_expected.not_to respond_to "event1" }
    it { is_expected.to respond_to "event2" }
  end
end
