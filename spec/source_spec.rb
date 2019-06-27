# frozen_string_literal: true

require "ettin/source"

RSpec.describe Ettin::Source do
  describe "#load" do
    it "is not implemented" do
      expect { described_class.new.load }.to raise_error(NotImplementedError)
    end
  end
end
