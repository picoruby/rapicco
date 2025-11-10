Gem::Specification.new do |spec|
  spec.name          = "rapicco"
  spec.version       = "0.1.0"
  spec.authors       = ["HASUMI Hitoshi"]
  spec.email         = []

  spec.summary       = "Rabbit-like presentation tool by PicoRuby"
  spec.description   = "A wrapper tool of PicoRuby Rapicco terminal-based presentation"
  spec.homepage      = "https://github.com/picoruby/rapicco"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "bin/*", "README.md", "LICENSE"]
  spec.bindir        = "bin"
  spec.executables   = ["rapicco"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0.0"

  spec.add_dependency "cairo", "~> 1.17"
  spec.add_dependency "ffi", "~> 1.15"
end
