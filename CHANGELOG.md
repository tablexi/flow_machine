# 0.2.1

* Calling a `may_xxx?` method when that transition is not defined for the current
  state now adds `:invalid_event` to the `guard_errors`. (PR #11, Issue #10)

# 0.2.0

* Class methods that used to be on the root `FlowMachine` have been moved to `FlowMachine::Workflow`. (deprecated in 0.1.1)

* To upgrade, change any occurences of:
    * `FlowMachine.workflow_for` to `FlowMachine::Workflow.for`
    * `FlowMachine::workflow_class_for` to `FlowMachine::Workflow.class_for`
    * `FlowMachine.workflow_collection_for` to `FlowMachine::Workflow.collection_for`

# 0.1.1 - 2015-04-01

* Deprecate `FlowMachine::Factory.workflow_for` in favor of `FlowMachine::Workflow.for`

# 0.1.0 - 2015-02-24

* Initial release
