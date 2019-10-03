$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "bplmodels/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "bplmodels"
  s.version     = Bplmodels::VERSION
  s.authors     = ["Steven Anderson", "Ben Barber", "Eben English"]
  s.email       = ["sanderson@bpl.org", "bbarber@bpl.org", "eenglish@bpl.org"]
  s.homepage    = "http://www.bpl.org"
  s.summary     = "Common Boston Library repository models."
  s.description = "Common Boston Library repository models."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'rails', '>= 4.2.11', '< 6'
  s.add_dependency 'mods', '~> 2.3', '>= 2.3.1'
  s.add_dependency 'active-fedora', '>= 8.0.1', '< 9'
  s.add_dependency 'hydra-file_characterization', '~> 1.0.0'
  s.add_dependency 'typhoeus'
  s.add_dependency 'om', '~> 3.0'
  s.add_dependency 'bpl-derivatives', '~> 0.2.1'
  # s.add_development_dependency "sqlite3"
end
