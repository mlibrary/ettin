# frozen_string_literal: true

require "ettin/sources/hash_source"

module Ettin
  RSpec.describe Sources::HashSource do
    it "takes a hash as initializer" do
      source = described_class.new(foo: 5)
      expect(source.load).to eq(foo: 5)
    end

    context "with a basic hash" do
      let(:source) do
        described_class.new(
          "size" => 2,
          "section" => {
            "size"    => 3,
            "servers" => [{ "name" => "yahoo.com" }, { "name" => "amazon.com" }]
          }
        )
      end

      it "properlies read the settings" do
        results = source.load
        expect(results["size"]).to eq(2)
      end

      it "properlies read nested settings" do
        results = source.load
        expect(results["section"]["size"]).to eq(3)
        expect(results["section"]["servers"]).to be_instance_of(Array)
        expect(results["section"]["servers"].size).to eq(2)
      end
    end

    context "when the parameter is not a hash" do
      let(:source) do
        described_class.new "hello world"
      end

      it "returns an empty hash" do
        results = source.load
        expect(results).to eq({})
      end
    end
  end
end
