require "deep_merge"
require "ettin/hash_source"
require "ettin/yaml_source"
require "ettin/options_source"
require "ettin/deep_transform"

module Ettin
  class HashFactory
    def build(*targets)
      hash = Hash.new(nil)
      targets
        .flatten
        .map{|target| source_for(target) }
        .map{|source| source.load }
        .map{|h| h.deep_transform_keys{|key| key.to_s.to_sym } }
        .each{|h| hash.deep_merge!(h, overwrite_arrays: true) }
      hash
    end

    private

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

