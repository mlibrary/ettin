# frozen_string_literal: true

require "ettin/sources/hash_source"

module Ettin
  RSpec.describe Sources::HashSource do
    it "should take a hash as initializer" do
      source = described_class.new(foo: 5)
      expect(source.load).to eq(foo: 5)
    end

    context "basic hash" do
      let(:source) do
        described_class.new(
          "size" => 2,
          "section" => {
            "size"    => 3,
            "servers" => [{ "name" => "yahoo.com" }, { "name" => "amazon.com" }]
          }
        )
      end

      it "should properly read the settings" do
        results = source.load
        expect(results["size"]).to eq(2)
      end

      it "should properly read nested settings" do
        results = source.load
        expect(results["section"]["size"]).to eq(3)
        expect(results["section"]["servers"]).to be_instance_of(Array)
        expect(results["section"]["servers"].size).to eq(2)
      end
    end

    context "parameter is not a hash" do
      let(:source) do
        described_class.new "hello world"
      end

      it "should return an empty hash" do
        results = source.load
        expect(results).to eq({})
      end
    end
  end
end
