# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trade_bot/version'

Gem::Specification.new do |spec|
  spec.name          = "trade_bot"
  spec.version       = TradeBot::VERSION
  spec.authors       = ["Sam Stelfox"]
  spec.email         = ["sstelfox@bedroomprogrammers.net"]
  spec.description   = %q{A system of ruby based MtGox bots.}
  spec.summary       = %q{Ruby based MtGox bots.}
  spec.homepage      = "http://stelfox.net/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "celluloid"
  spec.add_dependency "celluloid-redis"
  spec.add_dependency "celluloid-websocket-client"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
