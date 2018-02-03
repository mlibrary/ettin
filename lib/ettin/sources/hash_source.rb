# frozen_string_literal: true

require "ettin/source"

module Ettin
  class HashSource < Source
    register(self)

    def self.handles?(target)
      target.is_a? Hash
    end

    def initialize(hash)
      @hash = hash.is_a?(Hash) ? hash : {}
    end

    def load
      hash
    end

    private

    attr_reader :hash
  end
end
