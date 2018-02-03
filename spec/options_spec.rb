require 'spec_helper'
require "ettin/options"
require "json"
require "pathname"

# temporary require
require "ettin/builder"

describe Ettin::Options do
  let(:fixture_path) { Pathname.new(__FILE__).dirname/"fixtures" }

  describe "Unwanted features" do
    it "should allow full reload of the settings files", skip: "Bad feature: #reload not needed" do
      files = ["#{fixture_path}/settings.yml"]
      Config.load_and_set_settings(files)
      expect(Settings.server).to eq("google.com")
      expect(Settings.size).to eq(1)

      files = ["#{fixture_path}/settings.yml", "#{fixture_path}/development.yml"]
      Settings.reload_from_files(files)
      expect(Settings.server).to eq("google.com")
      expect(Settings.size).to eq(2)
    end

    context "Custom Configuration", skip: "Bad feature: just assign an object" do
      it "should have the default settings constant as 'Settings'" do
        expect(Config.const_name).to eq("Settings")
      end

      it "should be able to assign a different settings constant" do
        Config.setup { |config| config.const_name = "Settings2" }

        expect(Config.const_name).to eq("Settings2")
      end
    end

    context 'using knockout_prefix', skip: "Bad feature: Completely unnecessary" do
      context 'in configuration phase' do
        it 'should be able to assign a different knockout_prefix value' do
          Config.reset
          Config.knockout_prefix = '--'

          expect(Config.knockout_prefix).to eq('--')
        end

        it 'should have the default knockout_prefix value equal nil' do
          Config.reset

          expect(Config.knockout_prefix).to eq(nil)
        end
      end

      context 'merging' do
        let(:config) do
          Config.knockout_prefix = '--'
          Config.overwrite_arrays = false
          described_class.build(["#{fixture_path}/knockout_prefix/config1.yml",
                             "#{fixture_path}/knockout_prefix/config2.yml",
                             "#{fixture_path}/knockout_prefix/config3.yml"])
        end

        it 'should remove elements from settings' do
          expect(config.array1).to eq(['item4', 'item5', 'item6'])
          expect(config.array2.inner).to eq(['item4', 'item5', 'item6'])
          expect(config.array3).to eq('')
          expect(config.string1).to eq('')
          expect(config.string2).to eq('')
          expect(config.hash1.to_hash).to eq({ key1: '', key2: '', key3: 'value3' })
          expect(config.hash2).to eq('')
          expect(config.hash3.to_hash).to eq({ key4: 'value4', key5: 'value5' })
          expect(config.fixnum1).to eq('')
          expect(config.fixnum2).to eq('')
        end
      end
    end

    context 'prepending sources', skip: "Bad feature: requires full knowledge of state to use" do
      let(:config) do
        described_class.build("#{fixture_path}/settings.yml")
      end

      before do
        config.prepend_source!("#{fixture_path}/deep_merge2/config1.yml")
        config.reload!
      end

      it 'should still have the initial config' do
        expect(config['size']).to eq(1)
      end

      it 'should add keys from the added file' do
        expect(config['tvrage']['service_url']).to eq('http://services.tvrage.com')
      end

      context 'be overwritten' do
        before do
          config.prepend_source!("#{fixture_path}/deep_merge2/config2.yml")
          config.reload!
        end

        it 'should overwrite the previous values' do
          expect(config['tvrage']['service_url']).to eq('http://services.tvrage.com')
        end
      end

      context 'source is a hash' do
        let(:hash_source) {
          { tvrage: { service_url: 'http://url3' }, meaning_of_life: 42 }
        }
        before do
          config.prepend_source!(hash_source)
          config.reload!
        end

        it 'should be overwriten by the following values' do
          expect(config['tvrage']['service_url']).to eq('http://services.tvrage.com')
        end

        it 'should set meaning of life' do
          expect(config['meaning_of_life']).to eq(42)
        end
      end
    end

    context 'merging arrays', skip: "We always overwrite arrays" do
      let(:config) do
        described_class.build(
          "#{fixture_path}/deep_merge/config1.yml",
          "#{fixture_path}/deep_merge/config2.yml"
        )
      end

      it 'should merge hashes from multiple configs' do
        expect(config.inner.keys.size).to eq(3)
        expect(config.inner2.inner2_inner.keys.size).to eq(3)
      end

      it 'should merge arrays from multiple configs' do
        expect(config.arraylist1.size).to eq(6)
        expect(config.arraylist2.inner.size).to eq(6)
      end
    end

    context 'when Settings file is using keywords reserved for OpenStruct', skip: "Just use [] in these rare cases" do
      let(:config) do
        described_class.build("#{fixture_path}/reserved_keywords.yml")
      end

      it 'should allow to access them via object member notation' do
        expect(config.select).to eq(123)
        expect(config.collect).to eq(456)
        expect(config.count).to eq(789)
      end

      it 'should allow to access them using [] operator' do
        expect(config['select']).to eq(123)
        expect(config['collect']).to eq(456)
        expect(config['count']).to eq(789)

        expect(config[:select]).to eq(123)
        expect(config[:collect]).to eq(456)
        expect(config[:count]).to eq(789)
      end
    end

    describe "Validation", skip: "Bad feature: unnecessary" do
      let(:config) do
        files = ["#{fixture_path}/custom_types/hash.yml"]
        described_class.build(files)
      end

      it "should turn that setting into a Real Hash" do
        expect(config.prices).to be_kind_of(Hash)
      end

      it "should map the hash values correctly" do
        expect(config.prices[1]).to eq(2.99)
        expect(config.prices[5]).to eq(9.99)
        expect(config.prices[15]).to eq(19.99)
        expect(config.prices[30]).to eq(29.99)
      end
    end

    context 'when fail_on_missing option', skip: "Is this needed?" do
      context 'is set to true' do
        it 'should raise an error when accessing a missing key' do
          config = described_class.build("#{fixture_path}/empty1.yml")

          expect { config.not_existing_method }.to raise_error(KeyError)
          expect { config[:not_existing_method] }.to raise_error(KeyError)
        end

        it 'should raise an error when accessing a removed key' do
          config = described_class.build("#{fixture_path}/empty1.yml")

          config.tmp_existing = 1337
          expect(config.tmp_existing).to eq(1337)

          config.delete_field(:tmp_existing)
          expect { config.tmp_existing }.to raise_error(KeyError)
          expect { config[:tmp_existing] }.to raise_error(KeyError)
        end
      end

      context 'is set to false' do
        before { Config.setup { |cfg| cfg.fail_on_missing = false } }

        it 'should return nil when accessing a missing key' do
          config = described_class.build("#{fixture_path}/empty1.yml")

          expect(config.not_existing_method).to eq(nil)
          expect(config[:not_existing_method]).to eq(nil)
        end
      end
    end
  end # unwanted features

  it "should load a basic config file" do
    config = described_class.build(["#{fixture_path}/settings.yml"])
    expect(config.size).to eq(1)
    expect(config.server).to eq("google.com")
    expect(config['1']).to eq('one')
    expect(config.photo_sizes.avatar).to eq([60, 60])
    expect(config.root['yahoo.com']).to eq(2)
    expect(config.root['google.com']).to eq(3)
  end

  it "should load 2 basic config files" do
    config = described_class.build("#{fixture_path}/settings.yml", "#{fixture_path}/settings2.yml")
    expect(config.size).to eq(1)
    expect(config.server).to eq("google.com")
    expect(config.another).to eq("something")
  end

  it "should load empty config for a missing file path" do
    config = described_class.build("#{fixture_path}/some_file_that_doesnt_exist.yml")
    expect(config).to be_empty
  end

  it "should load an empty config for multiple missing file paths" do
    files  = ["#{fixture_path}/doesnt_exist1.yml", "#{fixture_path}/doesnt_exist2.yml"]
    config = described_class.build(files)
    expect(config).to be_empty
  end

  it "should load empty config for an empty setting file" do
    config = described_class.build("#{fixture_path}/empty1.yml")
    expect(config).to be_empty
  end

  it "should convert to a hash" do
    config = described_class.build("#{fixture_path}/development.yml").to_h
    expect(config[:section][:servers]).to be_kind_of(Array)
    expect(config[:section][:servers][0][:name]).to eq("yahoo.com")
    expect(config[:section][:servers][1][:name]).to eq("amazon.com")
  end

  it "should convert to a hash (We Need To Go Deeper)" do
    config  = described_class.build("#{fixture_path}/development.yml").to_h
    servers = config[:section][:servers]
    expect(servers).to eq([{ name: "yahoo.com" }, { name: "amazon.com" }])
  end

  it "should convert to a hash without modifying nested settings" do
    config = described_class.build("#{fixture_path}/development.yml")
    config.to_h
    expect(config).to be_kind_of(described_class)
    expect(config[:section]).to be_kind_of(described_class)
    expect(config[:section][:servers][0]).to be_kind_of(described_class)
    expect(config[:section][:servers][1]).to be_kind_of(described_class)
  end

  it "should be convertible to json" do
    config = JSON.dump(described_class.build("#{fixture_path}/development.yml").to_h)
    expect(JSON.parse(config)["section"]["servers"]).to be_kind_of(Array)
  end

  it "should load an empty config for multiple missing file paths" do
    files  = ["#{fixture_path}/empty1.yml", "#{fixture_path}/empty2.yml"]
    config = described_class.build(files)
    expect(config).to be_empty
  end

  it "should allow overrides" do
    files  = ["#{fixture_path}/settings.yml", "#{fixture_path}/development.yml"]
    config = described_class.build(files)
    expect(config.server).to eq("google.com")
    expect(config.size).to eq(2)
  end


  context "Nested Settings" do
    let(:config) do
      described_class.build("#{fixture_path}/development.yml")
    end

    it "should allow nested sections" do
      expect(config.section.size).to eq(3)
    end

    it "should allow configuration collections (arrays)" do
      expect(config.section.servers[0].name).to eq("yahoo.com")
      expect(config.section.servers[1].name).to eq("amazon.com")
    end
  end

  context "Settings with ERB tags" do
    let(:config) do
      described_class.build("#{fixture_path}/with_erb.yml")
    end

    it "should evaluate ERB tags" do
      expect(config.computed).to eq(6)
    end

    it "should evaluated nested ERB tags" do
      expect(config.section.computed1).to eq(1)
      expect(config.section.computed2).to eq(2)
    end
  end

  context "Boolean Overrides" do
    let(:config) do
      files = ["#{fixture_path}/bool_override/config1.yml", "#{fixture_path}/bool_override/config2.yml"]
      described_class.build(files)
    end

    it "should allow overriding of bool settings" do
      expect(config.override_bool).to eq(false)
      expect(config.override_bool_opposite).to eq(true)
    end
  end



  describe "defaults when key does not exist" do
    let(:config) { described_class.build({}) }
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

  context "Merging hash at runtime via #merge!" do
    let(:config) { described_class.build("#{fixture_path}/settings.yml") }
    let(:hash) { { :options => { :suboption => 'value' }, :server => 'amazon.com' } }

    it 'should be chainable' do
      expect(config.merge!({})).to eq(config)
    end

    it 'should preserve existing keys' do
      expect { config.merge!({}) }.to_not change { config.keys }
    end

    it 'should recursively merge keys' do
      config.merge!(hash)
      expect(config.options.suboption).to eq('value')
    end

    it 'should rewrite a merged value' do
      expect { config.merge!(hash) }.to change { config.server }.from('google.com').to('amazon.com')
    end
  end

  context "Merging hash at runtime via ::new" do
    let(:config) { described_class.build("#{fixture_path}/settings.yml") }
    let(:hash) { { :options => { :suboption => 'value' }, :server => 'amazon.com' } }

    it 'should be chainable' do
      expect(described_class.build(config, {})).to eq(config)
    end

    it 'should recursively merge keys' do
      new_config = described_class.build(config, hash)
      expect(new_config.options.suboption).to eq('value')
    end

    it 'should rewrite a merged value' do
      new_config = described_class.build(config, hash)
      expect(new_config.server).to eql("amazon.com")
    end
  end

  context "Merging nested hash at runtime via #merge!" do
    let(:config) { described_class.build("#{fixture_path}/deep_merge/config1.yml") }
    let(:hash) { { :inner => { :something1 => 'changed1', :something3 => 'changed3' } } }

    it 'should preserve first level keys' do
      expect { config.merge!(hash) }.to_not change { config.keys }
    end

    it 'should preserve nested key' do
      config.merge!(hash)
      expect(config.inner.something2).to eq('blah2')
    end

    it 'should add new nested key' do
      expect { config.merge!(hash) }
        .to change { config.inner.something3 }
        .from(nil)
        .to("changed3")
    end

    it 'should rewrite a merged value' do
      expect { config.merge!(hash) }.to change { config.inner.something1 }.from('blah1').to('changed1')
    end
  end

  context "Merging nested hash at runtime via ::new" do
    let(:config) { described_class.build("#{fixture_path}/deep_merge/config1.yml") }
    let(:hash) { { :inner => { :something1 => 'changed1', :something3 => 'changed3' } } }
    let(:new_config) { described_class.build(config, hash) }

    it 'should preserve first level keys' do
      expect(new_config.keys).to eql(config.keys)
    end

    it 'should preserve nested key' do
      expect(new_config.inner.something2).to eq('blah2')
    end

    it 'should add new nested key' do
      expect(new_config.inner.something3).to eql("changed3")
    end

    it 'should rewrite a merged value' do
      expect(new_config.inner.something1).to eql("changed1")
    end
  end

  context "[] accessors" do
    let(:config) do
      files = ["#{fixture_path}/development.yml"]
      described_class.build(files)
    end

    it "should access attributes using []" do
      expect(config.section['size']).to eq(3)
      expect(config.section[:size]).to eq(3)
      expect(config[:section][:size]).to eq(3)
    end

    it "should set values using []=" do
      config.section[:foo] = 'bar'
      expect(config.section.foo).to eq('bar')
    end
  end

  context "enumerable" do
    let(:config) do
      files = ["#{fixture_path}/development.yml"]
      described_class.build(files)
    end

    it "should enumerate top level parameters" do
      keys = []
      config.each { |key, value| keys << key }
      expect(keys).to eq([:size, :section])
    end

    it "should enumerate inner parameters" do
      keys = []
      config.section.each { |key, value| keys << key }
      expect(keys).to eq([:size, :servers])
    end

    it "should have methods defined by Enumerable" do
      expect(config.map { |key, value| key }).to eq([:size, :section])
    end
  end

  context "keys" do
    let(:config) do
      files = ["#{fixture_path}/development.yml"]
      described_class.build(files)
    end

    it "should return array of keys" do
      expect(config.keys).to contain_exactly(:size, :section)
    end

    it "should return array of keys for nested entry" do
      expect(config.section.keys).to contain_exactly(:size, :servers)
    end
  end

  context 'when loading settings files' do
    let(:config) do
      described_class.build(["#{fixture_path}/overwrite_arrays/config1.yml",
                         "#{fixture_path}/overwrite_arrays/config2.yml",
                         "#{fixture_path}/overwrite_arrays/config3.yml"])
    end

    it 'should remove elements from settings' do
      expect(config.array1).to eq(['item4', 'item5', 'item6'])
      expect(config.array2.inner).to eq(['item4', 'item5', 'item6'])
      expect(config.array3).to eq([])
    end

  end

  context 'adding sources' do
    let(:sources) { [fixture_path/"settings.yml", fixture_path/"deep_merge2"/"config1.yml"] }
    let(:sources) do
      [
        fixture_path/"settings.yml",
        fixture_path/"deep_merge2"/"config1.yml"
      ]
    end
    let(:config) { described_class.build(sources) }

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
      described_class.build([
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
