require "deep_merge"
require "yaml"
require "erb"
require "active_support/core_ext/hash/keys"
require "ettin/hash_source"
require "ettin/yaml_source"
require "ettin/options_source"

module Ettin
  class Options
    include Enumerable

    def initialize(*files)
      @hash = {}
      files
        .flatten
        .map{|target| source_for(target) }
        .map{|source| source.load }
        .map{|h| h.deep_transform_keys{|key| key.to_s.to_sym } }
        .each{|h| @hash.deep_merge!(h, overwrite_arrays: true) }
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

    def key?(key)
      hash.has_key?(key.to_s.to_sym)
    end
    alias_method :has_key?, :key?

    def [](key)
      convert(hash[key.to_s.to_sym])
    end

    def to_h
      hash
    end
    alias_method :to_hash, :to_h

    def empty?
      hash.empty?
    end

    def keys
      hash.keys
    end

    def eql?(other)
      to_h == other.to_h
    end
    alias_method :==, :eql?

    def each
      hash.each{|k,v| yield k, convert(v) }
    end

    private

    attr_reader :hash

    def convert(value)
      case value
      when Hash
        Options.new(value)
      when Array
        value.map{|i| convert(i)}
      else
        value
      end
    end

    def source_for(target)
      if target.is_a? Hash
        HashSource.new(target)
      elsif target.is_a? Options
        OptionsSource.new(target)
      else
        YAMLSource.new(target)
      end
    end

  end

end
