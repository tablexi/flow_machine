module FlowMachine
  class Factory
    def self.workflow_for(object, options = {})
      # If the object is enumerable, delegate. This allows workflow_for
      # as shorthand
      return workflow_for_collection(object, options) if object.respond_to?(:map)

      klazz = workflow_class_for(object)
      return nil unless klazz
      klazz.new(object, options)
    end

    def self.workflow_for_collection(collection, options = {})
      collection.map { |item| workflow_for(item, options) }
    end

    def self.workflow_class_for(object_or_class)
      if object_or_class.is_a? Class
        "#{object_or_class.name}Workflow".constantize
      else
        workflow_class_for(object_or_class.class)
      end
    rescue NameError # if the workflow class doesn't exist
      nil
    end
  end
end
