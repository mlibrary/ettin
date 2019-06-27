# frozen_string_literal: true

require "ettin/method_name"

RSpec.describe Ettin::MethodName do
  let(:normal_method) { :foo }
  let(:bang_method) { :foo! }
  let(:assign_method) { :foo= }

  describe "#to_sym" do
    it { expect(described_class.new("foo").to_sym).to eql(:foo) }
    it { expect(described_class.new(:foo).to_sym).to eql(:foo) }
    it { expect(described_class.new(assign_method).to_sym).to eql(assign_method) }
    it { expect(described_class.new(bang_method).to_sym).to eql(bang_method) }
  end

  describe "#to_s" do
    it { expect(described_class.new("foo").to_s).to eql("foo") }
    it { expect(described_class.new(:foo).to_s).to eql("foo") }
    it { expect(described_class.new(assign_method).to_s).to eql(assign_method.to_s) }
    it { expect(described_class.new(bang_method).to_s).to eql(bang_method.to_s) }
  end

  describe "#clean" do
    it { expect(described_class.new(assign_method).clean).to eql(normal_method) }
    it { expect(described_class.new(bang_method).clean).to eql(normal_method) }
    it { expect(described_class.new(normal_method).clean).to eql(normal_method) }
  end

  describe "#assignment?" do
    it { expect(described_class.new(assign_method).assignment?).to be true }
    it { expect(described_class.new(bang_method).assignment?).to be false }
    it { expect(described_class.new(normal_method).assignment?).to be false }
  end

  describe "#bang?" do
    it { expect(described_class.new(assign_method).bang?).to be false }
    it { expect(described_class.new(bang_method).bang?).to be true }
    it { expect(described_class.new(normal_method).bang?).to be false }
  end
end
