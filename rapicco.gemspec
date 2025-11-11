require_relative "lib/rapicco/version"
require_relative "lib/rapicco/constants"

Gem::Specification.new do |spec|
  spec.name          = "rapicco"
  spec.version       = Rapicco::VERSION
  spec.authors       = ["HASUMI Hitoshi"]
  spec.email         = []

  spec.summary       = "Rabbit-like presentation tool by PicoRuby"
  spec.description   = "A wrapper tool of PicoRuby Rapicco terminal-based presentation"
  spec.homepage      = "https://github.com/picoruby/rapicco"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "bin/*", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.bindir        = "bin"
  spec.executables   = ["rapicco"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Rapicco::REQUIRED_RUBY_VERSION

  spec.add_dependency "cairo", "~> 1.17"
  spec.add_dependency "rake", "~> 13.0"
end
