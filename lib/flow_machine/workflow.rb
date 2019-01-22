require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/try"
require "flow_machine/workflow/factory_methods"
require "flow_machine/workflow/model_extension"

module FlowMachine
  module Workflow
    extend FlowMachine::FactoryMethods

    def self.included(base)
      base.extend(ClassMethods)
      base.extend(ModelExtension)
      base.send(:attr_reader, :object)
    end

    module ClassMethods
      attr_accessor :callbacks

      def state_names
        states.keys.map(&:to_s)
      end

      def states
        @states ||= {}
      end

      # Mainly to be used in testing, call this method to ensure that
      # any dynamically created state methods get exposed to the workflow
      def refresh_state_methods!
        states.values.each do |state_class|
          add_state_methods_from(state_class)
        end
      end

      def state(state_class)
        name = get_state_name(state_class)
        states[name] = state_class
        add_state_methods_from(state_class)

        define_method "#{name}?" do
          current_state_name.to_s == name.to_s
        end
      end

      def state_attribute(method)
        @state_attribute = method
      end

      def state_method
        @state_attribute || :state
      end

      def before_save(*args, &block)
        add_callback(:before_save, FlowMachine::Callback.new(*args, &block))
      end

      def after_save(*args, &block)
        add_callback(:after_save, FlowMachine::Callback.new(*args, &block))
      end

      def after_transition(*args, &block)
        add_callback(:after_transition, FlowMachine::Callback.new(*args, &block))
      end

      private

      def add_callback(hook, callback)
        self.callbacks ||= {}
        callbacks[hook] ||= []
        callbacks[hook] << callback
      end

      # Defines an instance method on Workflow that delegates to the
      # current state. If the current state does not support the method, then
      # add an :invalid_event error to the guard_errors.
      def define_state_method(method_name)
        define_method method_name do |*args|
          if current_state.respond_to?(method_name)
            current_state.send(method_name, *args)
          else
            self.guard_errors = [:invalid_event]
            false
          end
        end
      end

      def add_state_methods_from(state_class)
        state_class.expose_to_workflow_methods.try(:each) do |method_name|
          define_state_method(method_name) unless method_defined?(method_name)
        end
      end

      def get_state_name(state_class)
        state_class.state_name
      end
    end

    attr_accessor :options, :previous_state_persistence_callbacks, :previous_state
    attr_accessor :changes

    # extend Forwardable
    # def_delegators :current_state, :guard_errors
    delegate :guard_errors, :guard_errors=, to: :current_state

    def initialize(object, options = {})
      @object = object
      @options = options
      @previous_state_persistence_callbacks = []
    end

    def current_state_name
      object.send(self.class.state_method)
    end
    alias state current_state_name

    def previous_state_name
      @previous_state.try(:name)
    end

    def current_state
      @current_state ||= self.class.states[current_state_name.to_sym].new(self)
    end

    def transition(options = {})
      @previous_state = current_state
      @current_state = nil
      self.current_state_name = options[:to].to_s if options[:to]
      @previous_state_persistence_callbacks << FlowMachine::StateCallback.new(options[:after]) if options[:after]
      fire_callbacks(:after_transition) unless previous_state == current_state
      current_state
    end

    def save
      persist
    end

    def persist
      self.changes = object.changes
      # If the model has a default state from the database, then it doesn't get
      # included in `changes` when you're first saving it.
      changes[state_method.to_s] ||= [nil, current_state_name] if object.new_record?

      fire_callbacks(:before_save)
      current_state.fire_callbacks(:before_change, changes)

      if persist_object
        fire_state_callbacks
        fire_callbacks(:after_save)
        true
      else
        self.current_state_name = @previous_state.name.to_s if @previous_state
        false
      end
    end

    # Useful for using in if/unless on state and after_save callbacks so you can
    # run the callback only on the initial persistence
    def create?
      changes[state_method.to_s].try(:first).blank?
    end

    def persist_object
      object.save
    end

    def current_state_name=(new_state)
      raise ArgumentError, "invalid state: #{new_state}" unless self.class.state_names.include?(new_state.to_s)

      object.send("#{self.class.state_method}=", new_state)
    end

    def current_user
      options[:current_user]
    end

    private

    def fire_callbacks(event)
      self.class.callbacks ||= {}
      self.class.callbacks[event].try(:each) do |callback|
        callback.call(self, changes)
      end
    end

    def fire_state_callbacks
      previous_state.fire_callback_list(previous_state_persistence_callbacks) if previous_state
      @previous_state_persistence_callbacks = []
      current_state.fire_callbacks(:after_enter, changes) if changes.include? state_method.to_s
      current_state.fire_callbacks(:after_change, changes)
    end

    def state_method
      self.class.state_method
    end
  end
end
