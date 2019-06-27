# frozen_string_literal: true

require "ettin"
require "pathname"

RSpec.describe Ettin do
  let(:fixture_path) { Pathname.new(__FILE__).dirname/"fixtures" }

  describe "::settings_files" do
    it "gets setting files" do
      config = described_class.settings_files("root/config", "test")
      expect(config).to eq([
        Pathname.new("root/config/settings.yml"),
        Pathname.new("root/config/settings/test.yml"),
        Pathname.new("root/config/environments/test.yml"),
        Pathname.new("root/config/settings.local.yml"),
        Pathname.new("root/config/settings/test.local.yml"),
        Pathname.new("root/config/environments/test.local.yml")
      ])
    end
  end

  describe "::for" do
    context "when loading a basic config file" do
      let(:config) { described_class.for(["#{fixture_path}/settings.yml"]) }

      it { expect(config.size).to eq(1) }
      it { expect(config.server).to eq("google.com") }
      it { expect(config["1"]).to eq("one") }
      it { expect(config.photo_sizes.avatar).to eq([60, 60]) }
      it { expect(config.root["yahoo.com"]).to eq(2) }
      it { expect(config.root["google.com"]).to eq(3) }
    end

    it "loads 2 basic config files" do
      config = described_class.for(
        "#{fixture_path}/settings.yml",
        "#{fixture_path}/settings2.yml"
      )
      expect(config.size).to eq(1)
      expect(config.server).to eq("google.com")
      expect(config.another).to eq("something")
    end

    it "loads empty config for a missing file path" do
      config = described_class.for("#{fixture_path}/some_file_that_doesnt_exist.yml")
      expect(config).to be_empty
    end

    it "loads an empty config for multiple missing file paths" do
      files  = ["#{fixture_path}/doesnt_exist1.yml", "#{fixture_path}/doesnt_exist2.yml"]
      config = described_class.for(files)
      expect(config).to be_empty
    end

    it "loads empty config for an empty setting file" do
      config = described_class.for("#{fixture_path}/empty1.yml")
      expect(config).to be_empty
    end

    it "loads an empty config for multiple empty files" do
      files  = ["#{fixture_path}/empty1.yml", "#{fixture_path}/empty2.yml"]
      config = described_class.for(files)
      expect(config).to be_empty
    end

    it "allows overrides" do
      files  = ["#{fixture_path}/settings.yml", "#{fixture_path}/development.yml"]
      config = described_class.for(files)
      expect(config.server).to eq("google.com")
      expect(config.size).to eq(2)
    end

    describe "Nested Settings" do
      let(:config) do
        described_class.for("#{fixture_path}/development.yml")
      end

      it "allows nested sections" do
        expect(config.section.size).to eq(3)
      end

      it "allows configuration collections (arrays)" do
        expect(config.section.servers[0].name).to eq("yahoo.com")
        expect(config.section.servers[1].name).to eq("amazon.com")
      end
    end

    describe "Settings with ERB tags" do
      let(:config) do
        described_class.for("#{fixture_path}/with_erb.yml")
      end

      it "evaluates ERB tags" do
        expect(config.computed).to eq(6)
      end

      it "evaluateds nested ERB tags" do
        expect(config.section.computed1).to eq(1)
        expect(config.section.computed2).to eq(2)
      end
    end

    describe "Boolean Overrides" do
      let(:config) do
        files = [
          "#{fixture_path}/bool_override/config1.yml",
          "#{fixture_path}/bool_override/config2.yml"
        ]
        described_class.for(files)
      end

      it "allows overriding of bool settings" do
        expect(config.override_bool).to eq(false)
        expect(config.override_bool_opposite).to eq(true)
      end
    end

    context "when merging hash at runtime via ::new" do
      let(:config) { described_class.for("#{fixture_path}/settings.yml") }
      let(:hash) { { options: { suboption: "value" }, server: "amazon.com" } }

      it "is chainable" do
        expect(described_class.for(config, {})).to eq(config)
      end

      it "recursivelies merge keys" do
        new_config = described_class.for(config, hash)
        expect(new_config.options.suboption).to eq("value")
      end

      it "rewrites a merged value" do
        new_config = described_class.for(config, hash)
        expect(new_config.server).to eql("amazon.com")
      end
    end

    context "when merging nested hash at runtime via ::new" do
      let(:config) { described_class.for("#{fixture_path}/deep_merge/config1.yml") }
      let(:hash) { { inner: { something1: "changed1", something3: "changed3" } } }
      let(:new_config) { described_class.for(config, hash) }

      it "preserves first level keys" do
        expect(new_config.keys).to eql(config.keys)
      end

      it "preserves nested key" do
        expect(new_config.inner.something2).to eq("blah2")
      end

      it "adds new nested key" do
        expect(new_config.inner.something3).to eql("changed3")
      end

      it "rewrites a merged value" do
        expect(new_config.inner.something1).to eql("changed1")
      end
    end

    context "when loading settings files" do
      let(:config) do
        described_class.for([
          "#{fixture_path}/overwrite_arrays/config1.yml",
          "#{fixture_path}/overwrite_arrays/config2.yml",
          "#{fixture_path}/overwrite_arrays/config3.yml"
        ])
      end

      it "removes elements from settings" do
        expect(config.array1).to eq(["item4", "item5", "item6"])
        expect(config.array2.inner).to eq(["item4", "item5", "item6"])
        expect(config.array3).to eq([])
      end
    end

    context "when we add additional sources" do
      let(:config) { described_class.for(sources) }
      let(:sources) do
        [
          fixture_path/"settings.yml",
          fixture_path/"deep_merge2"/"config1.yml"
        ]
      end

      it "still has the initial config" do
        expect(config["size"]).to eq(1)
      end

      it "adds keys from the added file" do
        expect(config["tvrage"]["service_url"]).to eq("http://services.tvrage.com")
      end
    end

    context "when we overwrite a key with a YAML source" do
      let(:config) { described_class.for(sources) }
      let(:sources) do
        [
          fixture_path/"settings.yml",
          fixture_path/"deep_merge2"/"config1.yml",
          fixture_path/"deep_merge2"/"config2.yml"
        ]
      end

      it "overwrites the previous values" do
        expect(config["tvrage"]["service_url"]).to eq("http://url2")
      end
    end

    context "when we overwrite a key with a Hash source" do
      let(:config) { described_class.for(sources) }
      let(:sources) do
        [
          fixture_path/"settings.yml",
          fixture_path/"deep_merge2"/"config1.yml",
          { tvrage: { service_url: "http://url3" } }
        ]
      end

      it "overwrites the previous values" do
        expect(config["tvrage"]["service_url"]).to eq("http://url3")
      end
    end
  end
end
