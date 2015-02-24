module FlowMachine
  # Deprecated in favor of calling these methods directly off of FlowMachine
  # which are defined in FlowMachine::FactoryMethods
  module Factory
    def self.workflow_for(object, options = {})
      deprecate :workflow_for, :for
      FlowMachine::Workflow.for(object, options)
    end

    def self.workflow_for_collection(collection, options = {})
      deprecate :workflow_for_collection, :for_collection
      FlowMachine::Workflow.for_collection(collection, options)
    end

    def self.workflow_class_for(object_or_class)
      deprecate :workflow_class_for, :class_for
      FlowMachine::Workflow.class_for(object_or_class)
    end

    def self.deprecate(old_method_name, new_method_name)
      warn "FlowMachine::Factory.#{old_method_name} is deprecated. Use FlowMachine::Workflow.#{new_method_name} instead."
    end
  end
end
