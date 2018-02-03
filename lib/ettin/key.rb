# frozen_string_literal: true

module Ettin
  class Key
    def initialize(key)
      @key = key
    end

    def inspect
      to_sym.inspect
    end

    def class
      Symbol
    end

    def to_s
      key.to_s
    end

    def to_sym
      to_s.to_sym
    end

    def eql?(other)
      to_sym = other.to_s.to_sym
    end
    alias_method :==, :eql?

    def hash
      key.to_s.to_sym.hash
    end

    private

    attr_reader :key

  end
end
