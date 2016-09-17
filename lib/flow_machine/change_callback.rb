class FlowMachine::ChangeCallback < FlowMachine::StateCallback
  attr_accessor :field

  def initialize(field, *args, &block)
    @field = field
    super(*args, &block)
  end

  def will_run?(object, changes = {})
    changes.keys.include?(field.to_s) && super
  end
end
