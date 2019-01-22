# frozen_string_literal: true

module FlowMachine
  class StateCallback < FlowMachine::Callback
    def run_method(target, method)
      target.run_workflow_method(method)
    end
  end
end
