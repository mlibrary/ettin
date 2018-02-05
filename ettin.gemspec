
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ettin/version"

Gem::Specification.new do |spec|
  spec.name          = "ettin"
  spec.version       = Ettin::VERSION
  spec.authors       = ["Bryan Hockey"]
  spec.email         = ["bhock@umich.edu"]

  spec.summary       = %q{The best way to add settings in any ruby project.}
  spec.description   = %q{Ettin handles loading environment-specific settings in an easy, simple,
                          and maintainable manner with minimal dependencies or magic.}
  spec.license       = "Revised BSD"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "deep_merge"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rubocop"
end
