# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-amqp2"
  gem.version       = "0.2.0"
  gem.authors       = ["Augusto Becciu", "Juan Manuel Barreneche"]
  gem.email         = ["devs@restorando.com"]

  gem.description   = %q{AMQP output plugin for Fluent}
  gem.summary       = %q{AMQP output plugin for Fluent}
  gem.homepage      = "https://github.com/restorando/fluent-plugin-amqp"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "fluentd", [">= 0.10.0", "< 2"]
  gem.add_dependency "bunny", ">= 0.10.8"
  gem.add_dependency "yajl-ruby", "~> 1.0"

  gem.add_development_dependency "rake", ">= 0.9.2"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "test-unit", ">= 3.1.0"
end
