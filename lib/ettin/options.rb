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
      @hash = Hash.new(nil)
      files
        .flatten
        .map{|target| source_for(target) }
        .map{|source| source.load }
        .map{|h| h.deep_transform_keys{|key| convert_key(key) } }
        .each{|h| @hash.deep_merge!(h, overwrite_arrays: true) }
    end

    def method_missing(method, *args, &block)
      super(method, *args, &block) unless respond_to?(method)
      if is_bang?(method) && !has_key?(debangify(method))
        raise KeyError, "key #{debangify(method)} not found"
      else
        self[debangify(method)]
      end
    end

    # We respond to:
    # * all methods our parents respond to
    # * all methods that are mostly alpha-numeric: /^[a-zA-Z_0-9]*$/
    # * all methods that are mostly alpha-numeric + !: /^[a-zA-Z_0-9]*\!$/
    def respond_to?(method, include_all = false)
      super(method, include_all) || /^[a-zA-Z_0-9]*\!?$/.match(method.to_s)
    end

    def key?(key)
      hash.has_key?(convert_key(key))
    end
    alias_method :has_key?, :key?

    def merge!(other)
      @hash.deep_merge!(other.to_h, overwrite_arrays: true)
    end

    def [](key)
      convert(hash[convert_key(key)])
    end

    def []=(key, value)
      hash[convert_key(key)] = value
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

    def is_bang?(method)
      method.to_s[-1] == "!"
    end

    def debangify(method)
      if is_bang?(method)
        method.to_s.chop.to_sym
      else
        method
      end
    end

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

    def convert_key(key)
      key.to_s.to_sym
    end

  end

end
