# frozen_string_literal: true

require "ostruct"

RSpec.describe FlowMachine::WorkflowState do
  class DraftClass < described_class
    def self.state_name
      :draft
    end
    on_exit { object.published_at = :exited_draft }
    event :publish do
      transition to: :published
    end
  end

  class PublishedClass < described_class
    def self.state_name
      :published
    end
    on_enter :entering
    on_exit :exiting
    def entering
      object.published_at = :entered_published
    end

    def exiting
      object.published_at = :exited_published
    end
    event :draft do
      transition to: :draft
    end
    event :to_self do
      transition to: :published
    end
  end

  class WorkflowTestClass
    include FlowMachine::Workflow
    state DraftClass
    state PublishedClass
  end

  let(:workflow) { WorkflowTestClass.new(object) }

  describe "when transitioning from draft to published" do
    let(:object) { OpenStruct.new(state: :draft) }

    it "triggers the entering of published state" do
      expect { workflow.publish }.to change(object, :published_at).to be(:entered_published)
    end
  end

  describe "when transitioning from published to draft" do
    let(:object) { OpenStruct.new(state: :published, published_at: :something) }

    it "triggers the exiting of published state" do
      expect { workflow.draft }.to change(object, :published_at).from(:something).to(:exited_published)
    end
  end

  describe "when transitioning from published to published" do
    let(:object) { OpenStruct.new(state: :published, published_at: :something) }

    it "does not trigger the on_enter or on_exit" do
      expect { workflow.to_self }.not_to change(object, :published_at)
    end
  end
end
