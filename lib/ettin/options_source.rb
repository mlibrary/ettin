module Ettin
  class OptionsSource
    def initialize(options)
      @hash = options.to_h
    end

    def load
      hash
    end

    private
    attr_reader :hash
  end
end
