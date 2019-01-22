# frozen_string_literal: true

RSpec.describe FlowMachine::Workflow do
  class TestClass; end

  class TestClassWorkflow
    include FlowMachine::Workflow
  end

  describe ".class_for" do
    subject(:workflow_class) { described_class.class_for(target) }

    describe "with a class" do
      let(:target) { TestClass }

      it { is_expected.to eq(TestClassWorkflow) }
    end

    describe "with an object" do
      let(:target) { TestClass.new }

      it { is_expected.to eq(TestClassWorkflow) }
    end
  end

  describe ".for" do
    subject(:workflow) { described_class.for(target) }

    class SomeNewClass; end

    describe "not found" do
      let(:target) { SomeNewClass.new }

      it { is_expected.to be_nil }
    end

    describe "with an object" do
      let(:target) { TestClass.new }

      it { is_expected.to be_an_instance_of(TestClassWorkflow) }
      its(:object) { is_expected.to eq(target) }
    end

    describe "with an array of objects" do
      let(:target) { [TestClass.new, TestClass.new] }

      it { is_expected.to match [an_instance_of(TestClassWorkflow), an_instance_of(TestClassWorkflow)] }
    end
  end

  describe ".workflow_for_collection" do
    subject(:result) { described_class.for_collection(target) }

    let(:target) { [TestClass.new, TestClass.new] }

    it { is_expected.to match [an_instance_of(TestClassWorkflow), an_instance_of(TestClassWorkflow)] }
  end
end
