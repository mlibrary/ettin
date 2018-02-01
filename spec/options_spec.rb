require 'spec_helper'
require "ettin/options"
require "pathname"

describe Ettin::Options do
  let(:fixture_path) { Pathname.new(__FILE__).dirname/"fixtures" }

  context 'adding sources' do
    let(:sources) { [fixture_path/"settings.yml", fixture_path/"deep_merge2"/"config1.yml"] }
    let(:sources) do
      [
        fixture_path/"settings.yml",
        fixture_path/"deep_merge2"/"config1.yml"
      ]
    end
    let(:config) { described_class.new(sources) }

    it 'should still have the initial config' do
      expect(config['size']).to eq(1)
    end

    it 'should add keys from the added file' do
      expect(config['tvrage']['service_url']).to eq('http://services.tvrage.com')
    end

    context 'overwrite with YAML file' do
      let(:sources) do
        [
          fixture_path/"settings.yml",
          fixture_path/"deep_merge2"/"config1.yml",
          fixture_path/"deep_merge2"/"config2.yml"
        ]
      end
      it 'should overwrite the previous values' do
        expect(config['tvrage']['service_url']).to eq('http://url2')
      end
    end

    context 'overwrite with Hash' do
      let(:sources) do
        [
          fixture_path/"settings.yml",
          fixture_path/"deep_merge2"/"config1.yml",
          {tvrage: {service_url: 'http://url3'}}
        ]
      end
      it 'should overwrite the previous values' do
        expect(config['tvrage']['service_url']).to eq('http://url3')
      end
    end
  end

  context '#key? and #has_key? methods' do
    let(:config) do
      described_class.new([
        fixture_path/"empty1.yml",
        {
          existing: nil,
          "complex_value" => nil,
          "even_more_complex_value=" => nil,
          nested: { existing: nil }
        }
      ])
    end

    it 'should test if a value exists for a given key' do
      expect(config.key?(:not_existing)).to eq(false)
      expect(config.key?(:complex_value)).to eq(true)
      expect(config.key?('even_more_complex_value='.to_sym)).to eq(true)
      expect(config.key?(:nested)).to eq(true)
      expect(config.nested.key?(:not_existing)).to eq(false)
      expect(config.nested.key?(:existing)).to eq(true)
    end

    it 'should not be sensible to key\'s class' do
      expect(config.key?(:existing)).to eq(true)
      expect(config.key?('existing')).to eq(true)
    end
  end
end
