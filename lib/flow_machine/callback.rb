require 'active_support/core_ext/array/extract_options'

class FlowMachine::Callback
  attr_accessor :method, :options

  def initialize(*args, &block)
    @options = args.extract_options!
    @method = args.shift unless block
    @block = block
  end

  def call(target, changes = {})
    return unless will_run? target, changes
    call!(target)
  end

  # Runs the callback without any validations
  def call!(target)
    run_method_or_lambda(target, method || @block)
  end

  def run_method_or_lambda(target, method)
    if method.respond_to? :call # is it a lambda
      target.instance_exec &method
    else
      run_method(target, method)
    end
  end

  def run_method(target, method)
    target.send(method)
  end

  def will_run?(target, changes = {})
    if options[:if]
      [*options[:if]].all? { |m| run_method_or_lambda(target, m) }
    elsif options[:unless]
      [*options[:unless]].none? { |m| run_method_or_lambda(target, m) }
    else
      true
    end
  end
end
