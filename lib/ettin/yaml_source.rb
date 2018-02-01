require "erb"
require "yaml"

module Ettin
  class YAMLSource
    def initialize(path)
      @path = path
    end

    def load
      return {} unless File.exist?(path)
      begin
        YAML.load(ERB.new(File.read(path)).result) || {}
      rescue Psych::SyntaxError => e
        raise "YAML syntax error occurred while parsing #{@path}. " \
          "Please note that YAML must be consistently indented using spaces. Tabs are not allowed. " \
          "Error: #{e.message}"
      end
    end

    private
    attr_reader :path
  end
end
