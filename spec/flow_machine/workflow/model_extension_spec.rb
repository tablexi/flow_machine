# frozen_string_literal: true

require "ostruct"

RSpec.describe FlowMachine::Workflow::ModelExtension do
  class Test1State < FlowMachine::WorkflowState
  end

  class Test2State < FlowMachine::WorkflowState
  end

  class TestWorkflow
    include FlowMachine::Workflow
    state Test1State
    state Test2State
  end

  describe ".create_scopes_on" do
    PersistedModel = Struct.new(:state) do
      def self.where(opts)
        [new(opts[:state])]
      end

      TestWorkflow.create_scopes_on(self)
    end

    UnPersistedModel = Struct.new(:state) do
      TestWorkflow.create_scopes_on(self)
    end

    it "adds the predicate model for state 1" do
      expect(PersistedModel.new("test1")).to be_test1
      expect(PersistedModel.new("test2")).not_to be_test1
    end

    it "adds the predicate model for state 2" do
      expect(PersistedModel.new("test1")).not_to be_test2
      expect(PersistedModel.new("test2")).to be_test2
    end

    it "adds a scope for test1" do
      expect(PersistedModel.test1).to be_an(Array)
      expect(PersistedModel.test1).to be_one
      expect(PersistedModel.test1.first).to eq(PersistedModel.new("test1"))
    end

    it "adds a scope for test2" do
      expect(PersistedModel.test2).to be_an(Array)
      expect(PersistedModel.test2).to be_one
      expect(PersistedModel.test2.first).to eq(PersistedModel.new("test2"))
    end

    it "does not add scopes if where is not defined" do
      expect(UnPersistedModel).not_to respond_to(:test1)
    end
  end
end
