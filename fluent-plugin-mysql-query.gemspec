$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-mysql-query"
  s.version     = "0.4.0"
  s.license     = "Apache-2.0"
  s.authors     = ["Kentaro Yoshida"]
  s.email       = ["y.ken.studio@gmail.com"]
  s.homepage    = "https://github.com/y-ken/fluent-plugin-mysql-query"
  s.summary     = %q{Fluentd Input plugin to execute mysql query and fetch rows. It is useful for stationary interval metrics measurement.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_development_dependency "test-unit", ">= 3.1.0"
  s.add_runtime_dependency "fluentd", "> 0.14.0", "< 2"
  s.add_runtime_dependency "mysql2"
end
