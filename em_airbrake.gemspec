# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "em_airbrake/version"

Gem::Specification.new do |s|
  s.name        = "em_airbrake"
  s.version     = EmAirbrake::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ismael Celis"]
  s.email       = ["ismaelct@gmail.com"]
  s.homepage    = "http://github.com/ismasan/em_airbrake"
  s.summary     = %q{Send error notifications to your Airbrake account from within EventMachine servers (Thin, EM)}
  s.description = %q{Async Airbrake notifier for EventMachine apps}
  
  s.add_dependency 'eventmachine', ">= 0.12.10"
  s.add_dependency 'em-http-request'
  
  s.rubyforge_project = "em_airbrake"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
