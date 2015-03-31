# Upgrading

## From 0.1 to 0.2

Class methods that used to be on the root `FlowMachine` have been moved to `FlowMachine::Workflow`.

Change all occurances of:

* `FlowMachine.workflow_for` to `FlowMachine::Workflow.for`
* `FlowMachine::workflow_class_for` to `FlowMachine::Workflow.class_for`
* `FlowMachine.workflow_collection_for` to `FlowMachine::Workflow.collection_for`

