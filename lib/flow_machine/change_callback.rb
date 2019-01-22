# frozen_string_literal: true

module FlowMachine
  class ChangeCallback < FlowMachine::StateCallback
    attr_accessor :field
    def initialize(field, *args, &block)
      @field = field
      super(*args, &block)
    end

    def will_run?(object, changes = {})
      changes.key?(field.to_s) && super
    end
  end
end
