require "ettin/key"

module Ettin
  class Options
    include Enumerable
    extend Forwardable

    def_delegators :@hash, :keys, :empty?

    def initialize(hash)
      @hash = hash
      @hash.deep_transform_keys!{|key| key.to_s.to_sym }
      @hash.default = nil
    end

    def method_missing(method, *args, &block)
      super(method, *args, &block) unless respond_to?(method)
      if is_bang?(method) && !has_key?(debang(method))
        raise KeyError, "key #{debang(method)} not found"
      else
        self[debang(method)]
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
      hash.has_key?(Key.new(key))
    end
    alias_method :has_key?, :key?

    def merge!(other)
      hash.deep_merge!(other.to_h, overwrite_arrays: true)
    end

    def [](key)
      convert(hash[Key.new(key)])
    end

    def []=(key, value)
      hash[Key.new(key)] = value
    end

    def to_h
      hash
    end
    alias_method :to_hash, :to_h

    def eql?(other)
      to_h == other.to_h
    end
    alias_method :==, :eql?

    def each
      hash.each{|k,v| yield k, convert(v) }
    end

    private

    attr_reader :hash

    def is_bang?(method)
      method.to_s[-1] == "!"
    end

    def debang(method)
      if is_bang?(method)
        method.to_s.chop.to_sym
      else
        method
      end
    end

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
  end

end
