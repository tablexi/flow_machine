# frozen_string_literal: true

# These methods are extended in the base FlowMachine module
module FlowMachine
  module FactoryMethods
    def for(object, options = {})
      # If the object is enumerable, delegate. This allows workflow_for
      # as shorthand
      return for_collection(object, options) if object.respond_to?(:map)

      klazz = class_for(object)
      return nil unless klazz

      klazz.new(object, options)
    end

    def for_collection(collection, options = {})
      collection.map { |item| self.for(item, options) }
    end

    def class_for(object_or_class)
      if object_or_class.is_a? Class
        "#{object_or_class.name}Workflow".constantize
      else
        class_for(object_or_class.class)
      end
    rescue NameError # if the workflow class doesn't exist
      nil
    end
  end
end
