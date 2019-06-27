# frozen_string_literal: true

require "ettin/sources/yaml_source"

module Ettin
  RSpec.describe Sources::YamlSource do
    let(:fixture_path) { Pathname.new(__FILE__).dirname/"fixtures" }

    context "with a basic yml file" do
      let(:source) do
        described_class.new "#{fixture_path}/development.yml"
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

    context "with a yml file that has erb tags" do
      let(:source) do
        described_class.new "#{fixture_path}/with_erb.yml"
      end

      it "properlies evaluate the erb" do
        results = source.load
        expect(results["computed"]).to eq(6)
      end

      it "properlies evaluate the nested erb settings" do
        results = source.load
        expect(results["section"]["computed1"]).to eq(1)
        expect(results["section"]["computed2"]).to eq(2)
      end
    end

    context "with a missing yml file" do
      let(:source) do
        described_class.new "somewhere_that_doesnt_exist.yml"
      end

      it "returns an empty hash" do
        results = source.load
        expect(results).to eq({})
      end
    end

    context "with a blank yml file" do
      let(:source) do
        described_class.new "#{fixture_path}/empty1.yml"
      end

      it "returns an empty hash" do
        results = source.load
        expect(results).to eq({})
      end
    end

    context "with a malformed yml file" do
      let(:source) do
        described_class.new "#{fixture_path}/malformed.yml"
      end

      it "raises an useful exception" do
        expect { source.load }.to raise_error(/malformed\.yml/)
      end
    end
  end
end
