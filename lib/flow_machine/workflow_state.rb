require "active_support/inflector"

class FlowMachine::WorkflowState
  attr_reader :workflow
  attr_accessor :guard_errors

  extend Forwardable
  def_delegators :workflow, :object, :options

  module ClassMethods
    attr_accessor :state_callbacks
    attr_accessor :expose_to_workflow_methods

    def state_name
      name.demodulize.sub(/State\z/, '').underscore.to_sym
    end

    # Maintains a list of methods that should be exposed to the workflow
    # the workflow is responsible for reading this list
    def expose_to_workflow(name)
      self.expose_to_workflow_methods ||= []
      self.expose_to_workflow_methods << name
    end

    def event(name, options = {}, &block)
      define_may_event(name, options)
      define_event(name, options, &block)
      define_event_bang(name)
    end

    private

    def define_event(name, options, &block)
      define_method name do |*args|
        return false unless self.send("may_#{name}?")
        instance_exec *args, &block
      end
      expose_to_workflow name
    end

    def define_may_event(name, options)
      define_method "may_#{name}?" do
        run_guard_methods([*options[:guard]])
      end
      expose_to_workflow "may_#{name}?"
    end

    def define_event_bang(name)
      define_method "#{name}!" do |*args|
        workflow.persist if self.send(name, *args)
      end
      expose_to_workflow "#{name}!"
    end
  end
  extend ClassMethods

  # Callbacks may be a symbol method name on the state, workflow, or underlying object,
  # and will look for that method on those objects in that order. You may also
  # use a block.
  # Callbacks will accept :if and :unless options, which also may be method name
  # symbols or blocks. The option accepts an array meaning all methods must return
  # true (for if) and false (for unless)
  #
  # class ExampleState < Workflow::State
  #   on_enter :some_method, if: :allowed?
  #   after_enter :after_enter_method, if: [:this_is_true?, :and_this_is_true?]
  #   before_change(:field_name) { do_something }
  # end
  #
  module CallbackDsl
    # Called when the workflow `transition`s to the state
    def on_enter(*args, &block)
      add_callback(:on_enter, FlowMachine::StateCallback.new(*args, &block))
    end

    # Called after `persist` when the workflow transitioned into this state
    def after_enter(*args, &block)
      add_callback(:after_enter, FlowMachine::StateCallback.new(*args, &block))
    end

    # Happens before persistence if the field on the object has changed
    def before_change(field, *args, &block)
      add_callback(:before_change, FlowMachine::ChangeCallback.new(field, *args, &block))
    end

    # Happens after persistence if the field on the object has changed
    def after_change(field, *args, &block)
      add_callback(:after_change, FlowMachine::ChangeCallback.new(field, *args, &block))
    end

    private

    def add_callback(hook, callback)
      self.state_callbacks ||= {}
      state_callbacks[hook] ||= []
      state_callbacks[hook] << callback
    end
  end
  extend CallbackDsl

  def initialize(workflow)
    @workflow = workflow
    @guard_errors = []
  end

  def fire_callback_list(callbacks, changes = {})
    callbacks.each do |callback|
      callback.call(self, changes)
    end
  end

  def fire_callbacks(event, changes = {})
    return unless self.class.state_callbacks && self.class.state_callbacks[event]
    fire_callback_list self.class.state_callbacks[event], changes
  end

  # Allows method calls to fallback up the object chain so
  # guards and other methods can be defined on the object or workflow
  # as well as the state
  def run_workflow_method(method_name, *args, &block)
    if target = object_chain(method_name)
      target.send(method_name, *args, &block)
    else
      raise NoMethodError.new("undefined method #{method_name}", method_name)
    end
  end

  def transition(options = {})
    workflow.transition(options).tap do |new_state|
      new_state.fire_callbacks(:on_enter) if new_state
    end
  end

  def name
    self.class.state_name
  end

  def ==(other)
    self.class == other.class
  end

  private

  def run_guard_methods(guard_methods)
    self.guard_errors = []
    # Use inject to ensure that all guard methods are run.
    # all? short circuits on first false value
    guard_methods.inject(true) do |valid, guard_method|
      if self.run_workflow_method(guard_method)
        valid
      else
        self.guard_errors << guard_method
        false
      end
    end
    #
  end

  def object_chain(method_name)
    [self, workflow, object].find { |o| o.respond_to?(method_name, true) }
  end
end
