RSpec.describe FlowMachine::Factory do
  class TestClass; end

  class TestClassWorkflow
    include FlowMachine::Workflow
  end

  describe '.workflow_class_for' do
    subject(:workflow_class) { described_class.workflow_class_for(target) }
    before { expect(described_class).to receive(:deprecate) }

    describe 'with a class' do
      let(:target) { TestClass }
      it { should eq(TestClassWorkflow) }
    end

    describe 'with an object' do
      let(:target) { TestClass.new }
      it { should eq(TestClassWorkflow) }
    end
  end

  describe '.workflow_for' do
    subject(:workflow) { described_class.workflow_for(target) }
    before { expect(described_class).to receive(:deprecate) }

    class SomeNewClass; end

    describe 'not found' do
      let(:target) { SomeNewClass.new }
      it { should be_nil }
    end

    describe 'with an object' do
      let(:target) { TestClass.new }
      it { should be_an_instance_of(TestClassWorkflow) }
      its(:object) { should eq(target) }
    end

    describe 'with an array of objects' do
      let(:target) { [TestClass.new, TestClass.new] }
      it { should match [an_instance_of(TestClassWorkflow), an_instance_of(TestClassWorkflow)] }
    end
  end

  describe '.workflow_for_collection' do
    subject(:result) { described_class.workflow_for_collection(target) }
    before { expect(described_class).to receive(:deprecate) }

    let(:target) { [TestClass.new, TestClass.new] }
    it { should match [an_instance_of(TestClassWorkflow), an_instance_of(TestClassWorkflow)] }
  end
end
