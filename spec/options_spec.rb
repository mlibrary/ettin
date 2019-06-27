# frozen_string_literal: true

require "ettin/options"
require "json"

RSpec.describe Ettin::Options do
  describe "#to_h, #to_hash" do
    let(:config) { described_class.new(hash) }
    let(:hash) do
      {
        size: 2, section: {
          size: 3, servers: [
            { name: "yahoo.com" },
            { name: "amazon.com" }
          ]
        }
      }
    end

    it "converts to a hash" do
      expect(config.to_h[:section][:servers]).to be_kind_of(Array)
      expect(config.to_h[:section][:servers][0][:name]).to eq("yahoo.com")
      expect(config.to_h[:section][:servers][1][:name]).to eq("amazon.com")
    end

    it "converts to a hash (We Need To Go Deeper)" do
      servers = config.to_h[:section][:servers]
      expect(servers).to eq([{ name: "yahoo.com" }, { name: "amazon.com" }])
    end

    it "converts to a hash without modifying nested settings" do
      config.to_h
      expect(config).to be_kind_of(described_class)
      expect(config[:section]).to be_kind_of(described_class)
      expect(config[:section][:servers][0]).to be_kind_of(described_class)
    end

    it "is convertible to json" do
      json = JSON.dump(config.to_h)
      expect(JSON.parse(json)["section"]["servers"]).to be_kind_of(Array)
    end
  end

  describe "defaults when key does not exist" do
    let(:config) { described_class.new({}) }

    it "returns nil with dot notation" do
      expect(config.foo).to be_nil
    end

    it "returns nil with []" do
      expect(config[:foo]).to be_nil
    end

    it "raises KeyError with dot! notation" do
      expect { config.foo! }.to raise_error(KeyError)
    end
  end

  context "when merging with a hash at runtime via #merge" do
    let(:config) { described_class.new(hash) }
    let(:hash) do
      { size: 1, server: "google.com" }
    end
    let(:other_hash) { { options: { suboption: "value" }, server: "amazon.com" } }

    it "does not mutate the class" do
      expect(config.merge({}).class).to eql(described_class)
    end

    it "is chainable" do
      expect(config.merge({})).to eq(config)
    end

    it "preserves existing keys" do
      expect(config.merge({}).keys).to eql(config.keys)
    end

    it "recursivelies merge keys" do
      expect(config.merge(other_hash).options.suboption).to eql("value")
    end

    it "does not mutate" do
      expect { config.merge(other_hash) }.not_to change(config, :server)
    end

    it "rewrites a merged value" do
      expect(config.merge(other_hash).server).to eql("amazon.com")
    end
  end

  context "when merging with a nested hash at runtime via #merge" do
    let(:config) { described_class.new(hash) }
    let(:hash) do
      {
        size: 1, server: "google.com",
        inner: { something1: "blah1", something2: "blah2" }
      }
    end
    let(:other_hash) { { inner: { something1: "changed1", something3: "changed3" } } }

    it "preserves first level keys" do
      expect(config.merge(other_hash).keys).to eql(config.keys)
    end

    it "preserves nested key" do
      expect(config.merge(other_hash).inner.something2).to eq("blah2")
    end

    it "adds new nested key" do
      expect(config.merge(other_hash).inner.something3).to eql("changed3")
    end

    it "does not mutate" do
      expect { config.merge(other_hash) }.not_to change { config.inner.something1 }
    end

    it "rewrites a merged value" do
      expect(config.merge(other_hash).inner.something1).to eql("changed1")
    end
  end

  context "when merging with a hash at runtime via #merge!" do
    let(:config) { described_class.new(hash) }
    let(:hash) do
      { size: 1, server: "google.com" }
    end
    let(:other_hash) { { options: { suboption: "value" }, server: "amazon.com" } }

    it "does not mutate the class" do
      expect(config.merge!({}).class).to eql(described_class)
    end

    it "is chainable" do
      expect(config.merge!({})).to eq(config)
    end

    it "preserves existing keys" do
      expect { config.merge!({}) }.not_to change(config, :keys)
    end

    it "recursivelies merge keys" do
      config.merge!(other_hash)
      expect(config.options.suboption).to eq("value")
    end

    it "rewrites a merged value" do
      expect { config.merge!(other_hash) }.to change(config, :server)
        .from("google.com").to("amazon.com")
    end
  end

  context "when merging with a nested hash at runtime via #merge!" do
    let(:config) { described_class.new(hash) }
    let(:hash) do
      {
        size: 1, server: "google.com",
        inner: { something1: "blah1", something2: "blah2" }
      }
    end
    let(:other_hash) { { inner: { something1: "changed1", something3: "changed3" } } }

    it "preserves first level keys" do
      expect { config.merge!(other_hash) }.not_to change(config, :keys)
    end

    it "preserves nested key" do
      config.merge!(other_hash)
      expect(config.inner.something2).to eq("blah2")
    end

    it "adds new nested key" do
      expect { config.merge!(other_hash) }
        .to change { config.inner.something3 }
        .from(nil)
        .to("changed3")
    end

    it "rewrites a merged value" do
      expect { config.merge!(other_hash) }.to change { config.inner.something1 }
        .from("blah1").to("changed1")
    end
  end

  describe "[] accessors" do
    let(:config) { described_class.new(hash) }
    let(:hash) do
      {
        size: 2, section: {
          size: 3, servers: [
            { name: "yahoo.com" },
            { name: "amazon.com" }
          ]
        }
      }
    end

    it "accesses attributes using []" do
      expect(config.section["size"]).to eq(3)
      expect(config.section[:size]).to eq(3)
      expect(config[:section][:size]).to eq(3)
    end

    it "sets values using []=" do
      config.section[:foo] = "bar"
      expect(config.section.foo).to eq("bar")
    end
  end

  describe "enumerable" do
    let(:config) { described_class.new(hash) }
    let(:hash) do
      {
        size: 2, section: {
          size: 3, servers: [
            { name: "yahoo.com" },
            { name: "amazon.com" }
          ]
        }
      }
    end

    it "enumerates top level parameters" do
      keys = []
      config.each {|key, _| keys << key }
      expect(keys).to eq([:size, :section])
    end

    it "enumerates inner parameters" do
      keys = []
      config.section.each {|key, _| keys << key }
      expect(keys).to eq([:size, :servers])
    end

    it "has methods defined by Enumerable" do
      expect(config.map {|key, _| key }).to eq([:size, :section])
    end
  end

  describe "#keys" do
    let(:config) { described_class.new(hash) }
    let(:hash) do
      {
        size: 2, section: {
          size: 3, servers: [
            { name: "yahoo.com" },
            { name: "amazon.com" }
          ]
        }
      }
    end

    it "returns array of keys" do
      expect(config.keys).to contain_exactly(:size, :section)
    end

    it "returns array of keys for nested entry" do
      expect(config.section.keys).to contain_exactly(:size, :servers)
    end
  end

  describe "#key? and #has_key? methods" do
    let(:config) do
      described_class.new(
        existing: 1,
        "complex_value" => 2,
        "even_more_complex_value=" => 3,
        nested: { existing: 4 }
      )
    end

    it { expect(config.key?(:not_existing)).to eq(false) }
    it { expect(config.key?(:complex_value)).to eq(true) }
    it { expect(config.key?("even_more_complex_value=".to_sym)).to eq(true) }
    it { expect(config.key?(:nested)).to eq(true) }
    it { expect(config.nested.key?(:not_existing)).to eq(false) }
    it { expect(config.nested.key?(:existing)).to eq(true) }

    it "is not sensitive to key's class" do
      expect(config.key?(:existing)).to eq(true)
      expect(config.key?("existing")).to eq(true)
    end
  end
end
