require "deep_merge"
require "yaml"
require "erb"
require "active_support/core_ext/hash/keys"

module Ettin
  class Options
    def initialize(files)
      @hash = {}
      files
        .map{|file| hashify(file) }
        .map{|hash| hash.deep_symbolize_keys }
        .each{|hash| @hash.deep_merge!(hash) }
    end

    def method_missing(method, *args, &block)
      if respond_to?(method)
        self[method]
      else
        super(method, *args, block)
      end
    end

    def respond_to?(method, include_all = false)
      super(method, include_all) || self.has_key?(method)
    end

    def hashify(target)
      return target if target.is_a? Hash
      YAML.load(ERB.new(File.read(target)).result) || {}
    end

    def key?(key)
      @hash.has_key?(key.to_sym)
    end
    alias_method :has_key?, :key?

    def [](key)
      value = @hash[key.to_sym]
      if value.is_a? Hash
        Options.new([value])
      else
        value
      end
    end
  end

end
