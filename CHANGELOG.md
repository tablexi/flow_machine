# 0.2.3 - 2019-01-22

* Add `on_exit` callback for states (https://github.com/tablexi/flow_machine/pull/15)
* Run rubocop (https://github.com/tablexi/flow_machine/pull/16)

# 0.2.2 - 2019-01-11

* Fix issue where the scopes and predicates created by `FlowMachine::Workflow.create_scopes_on`
  use the wrong attribute. (https://github.com/tablexi/flow_machine/pull/14)
* Upgrade to RSpec 3.8
* Run test suite using Circle 2.0

# 0.2.1 - 2015-10-21

* Calling a `may_xxx?` method when that transition is not defined for the current
  state now adds `:invalid_event` to the `guard_errors`. (PR #11, Issue #10)

# 0.2.0 - 2015-04-01

* Class methods that used to be on the root `FlowMachine` have been moved to `FlowMachine::Workflow`. (deprecated in 0.1.1)

* To upgrade, change any occurences of:
    * `FlowMachine.workflow_for` to `FlowMachine::Workflow.for`
    * `FlowMachine::workflow_class_for` to `FlowMachine::Workflow.class_for`
    * `FlowMachine.workflow_collection_for` to `FlowMachine::Workflow.collection_for`

# 0.1.1 - 2015-04-01

* Deprecate `FlowMachine::Factory.workflow_for` in favor of `FlowMachine::Workflow.for`

# 0.1.0 - 2015-02-24

* Initial release
