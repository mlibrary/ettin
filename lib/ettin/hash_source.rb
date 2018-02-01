module Ettin
  class HashSource
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
