$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "flow_machine/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "flow_machine"
  s.version     = FlowMachine::VERSION
  s.authors     = ["Jason Hanggi"]
  s.email       = ["jason@tablexi.com"]
  s.homepage    = "http://www.github.com/tablexi/flow_machine"
  s.summary     = "A class-based state machine."
  s.description = "Build finite state machines in a backend-agnostic, class-centric way."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "activesupport", ">= 3.2"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "rubocop"
end
