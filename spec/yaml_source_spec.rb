# frozen_string_literal: true

require "ettin/sources/yaml_source"

module Ettin
  describe YAMLSource do
    let(:fixture_path) { Pathname.new(__FILE__).dirname/"fixtures" }

    context "basic yml file" do
      let(:source) do
        described_class.new "#{fixture_path}/development.yml"
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

    context "yml file with erb tags" do
      let(:source) do
        described_class.new "#{fixture_path}/with_erb.yml"
      end

      it "should properly evaluate the erb" do
        results = source.load
        expect(results["computed"]).to eq(6)
      end

      it "should properly evaluate the nested erb settings" do
        results = source.load
        expect(results["section"]["computed1"]).to eq(1)
        expect(results["section"]["computed2"]).to eq(2)
      end
    end

    context "missing yml file" do
      let(:source) do
        described_class.new "somewhere_that_doesnt_exist.yml"
      end

      it "should return an empty hash" do
        results = source.load
        expect(results).to eq({})
      end
    end

    context "blank yml file" do
      let(:source) do
        described_class.new "#{fixture_path}/empty1.yml"
      end

      it "should return an empty hash" do
        results = source.load
        expect(results).to eq({})
      end
    end

    context "malformed yml file" do
      let(:source) do
        described_class.new "#{fixture_path}/malformed.yml"
      end

      it "should raise an useful exception" do
        expect { source.load }.to raise_error(/malformed\.yml/)
      end
    end
  end
end
