# frozen_string_literal: true

require "ettin/config_files"
require "pathname"

module Ettin
  describe ConfigFiles do
    it "should get setting files" do
      config = described_class.for(root: "root/config", env: "test")
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
end
