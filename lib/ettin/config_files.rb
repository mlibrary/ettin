require "pathname"

module Ettin
  class ConfigFiles

    def self.for(root:, env:)
      root = Pathname.new(root)
      [
        root/"settings.yml",
        root/"settings"/"#{env}.yml",
        root/"environments"/"#{env}.yml",
        root/"settings.local.yml",
        root/"settings"/"#{env}.local.yml",
        root/"environments"/"#{env}.local.yml"
      ]
    end

  end
end
