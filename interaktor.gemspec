Gem::Specification.new do |spec|
  spec.name = "interaktor"
  spec.version = "0.5.1"

  spec.author = "Taylor Thurlow"
  spec.email = "thurlow@hey.com"
  spec.description = "A common interface for building service objects."
  spec.summary = "Simple service object implementation"
  spec.homepage = "https://github.com/taylorthurlow/interaktor"
  spec.license = "MIT"
  spec.files = `git ls-files`.split
  spec.required_ruby_version = ">= 3.0"
  spec.require_path = "lib"

  spec.add_runtime_dependency "activemodel", ">= 7.0.9"
  spec.add_runtime_dependency "zeitwerk", ">= 2"

  spec.add_development_dependency "rake", "~> 13.0"
end
