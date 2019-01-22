# frozen_string_literal: true

module FlowMachine
  module Workflow
    module ModelExtension
      # resolves to
      # class Model
      #   def self.published
      #     where(status: 'published')
      #   end
      #
      #   def published?
      #     self.status == 'published'
      #   end
      # end
      def create_scopes_on(content_class)
        state_method = self.state_method
        state_names.each do |status|
          # Don't add the scope classes if `where` is not defined since it means
          # you're likely not in a ORM class.
          if content_class.respond_to?(:where)
            content_class.singleton_class.send(:define_method, status) do
              where(state_method => status)
            end
          end

          content_class.send(:define_method, "#{status}?") do
            public_send(state_method) == status
          end
        end
      end
    end
  end
end
