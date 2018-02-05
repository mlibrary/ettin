# frozen_string_literal: true

require "deep_merge"
require "ettin/deep_transform"
require "ettin/source"
require "ettin/key"

module Ettin

  # Loads and deeply merges targets into a hash structure.
  class HashFactory
    def build(*targets)
      hash = Hash.new(nil)
      targets
        .flatten
        .map {|target| Source.for(target) }
        .map(&:load)
        .map {|h| h.deep_transform_keys {|key| Key.new(key) } }
        .each {|h| hash.deep_merge!(h, overwrite_arrays: true) }
      hash
    end
  end
end
