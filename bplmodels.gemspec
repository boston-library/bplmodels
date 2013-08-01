$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "bplmodels/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "bplmodels"
  s.version     = Bplmodels::VERSION
  s.authors     = ["Steven Anderson"]
  s.email       = ["sanderson@bpl.org"]
  s.homepage    = "http://www.bpl.org"
  s.summary     = "Common Boston Library repository models."
  s.description = "Common Boston Library repository models."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"
  s.add_dependency "mods"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
end
