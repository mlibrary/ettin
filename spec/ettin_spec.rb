require "ettin"
require "pathname"


describe Ettin do
  let(:fixture_path) { Pathname.new(__FILE__).dirname/"fixtures" }

  describe "::settings_files" do
    it "should get setting files" do
      config = described_class.settings_files("root/config", "test")
      expect(config).to eq([
        Pathname.new('root/config/settings.yml'),
        Pathname.new('root/config/settings/test.yml'),
        Pathname.new('root/config/environments/test.yml'),
        Pathname.new('root/config/settings.local.yml'),
        Pathname.new('root/config/settings/test.local.yml'),
        Pathname.new('root/config/environments/test.local.yml'),
      ])
    end
  end

  describe "::for" do
    it "should load a basic config file" do
      config = described_class.for(["#{fixture_path}/settings.yml"])
      expect(config.size).to eq(1)
      expect(config.server).to eq("google.com")
      expect(config['1']).to eq('one')
      expect(config.photo_sizes.avatar).to eq([60, 60])
      expect(config.root['yahoo.com']).to eq(2)
      expect(config.root['google.com']).to eq(3)
    end

    it "should load 2 basic config files" do
      config = described_class.for("#{fixture_path}/settings.yml", "#{fixture_path}/settings2.yml")
      expect(config.size).to eq(1)
      expect(config.server).to eq("google.com")
      expect(config.another).to eq("something")
    end

    it "should load empty config for a missing file path" do
      config = described_class.for("#{fixture_path}/some_file_that_doesnt_exist.yml")
      expect(config).to be_empty
    end

    it "should load an empty config for multiple missing file paths" do
      files  = ["#{fixture_path}/doesnt_exist1.yml", "#{fixture_path}/doesnt_exist2.yml"]
      config = described_class.for(files)
      expect(config).to be_empty
    end

    it "should load empty config for an empty setting file" do
      config = described_class.for("#{fixture_path}/empty1.yml")
      expect(config).to be_empty
    end

    it "should load an empty config for multiple missing file paths" do
      files  = ["#{fixture_path}/empty1.yml", "#{fixture_path}/empty2.yml"]
      config = described_class.for(files)
      expect(config).to be_empty
    end

    it "should allow overrides" do
      files  = ["#{fixture_path}/settings.yml", "#{fixture_path}/development.yml"]
      config = described_class.for(files)
      expect(config.server).to eq("google.com")
      expect(config.size).to eq(2)
    end


    context "Nested Settings" do
      let(:config) do
        described_class.for("#{fixture_path}/development.yml")
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
        described_class.for("#{fixture_path}/with_erb.yml")
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
        described_class.for(files)
      end

      it "should allow overriding of bool settings" do
        expect(config.override_bool).to eq(false)
        expect(config.override_bool_opposite).to eq(true)
      end
    end

    context "Merging hash at runtime via ::new" do
      let(:config) { described_class.for("#{fixture_path}/settings.yml") }
      let(:hash) { { :options => { :suboption => 'value' }, :server => 'amazon.com' } }

      it 'should be chainable' do
        expect(described_class.for(config, {})).to eq(config)
      end

      it 'should recursively merge keys' do
        new_config = described_class.for(config, hash)
        expect(new_config.options.suboption).to eq('value')
      end

      it 'should rewrite a merged value' do
        new_config = described_class.for(config, hash)
        expect(new_config.server).to eql("amazon.com")
      end
    end

    context "Merging nested hash at runtime via ::new" do
      let(:config) { described_class.for("#{fixture_path}/deep_merge/config1.yml") }
      let(:hash) { { :inner => { :something1 => 'changed1', :something3 => 'changed3' } } }
      let(:new_config) { described_class.for(config, hash) }

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

    context 'when loading settings files' do
      let(:config) do
        described_class.for(["#{fixture_path}/overwrite_arrays/config1.yml",
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
      let(:sources) do
        [
          fixture_path/"settings.yml",
          fixture_path/"deep_merge2"/"config1.yml"
        ]
      end
      let(:config) { described_class.for(sources) }

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
  end

end
