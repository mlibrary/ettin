require "deep_merge"
require "ettin/deep_transform"
require "ettin/source"

module Ettin
  class HashFactory
    def build(*targets)
      hash = Hash.new(nil)
      targets
        .flatten
        .map{|target| Source.for(target) }
        .map{|source| source.load }
        .map{|h| h.deep_transform_keys{|key| key.to_s.to_sym } }
        .each{|h| hash.deep_merge!(h, overwrite_arrays: true) }
      hash
    end
  end
end

