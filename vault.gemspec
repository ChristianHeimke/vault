lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "vault/version.rb"

Gem::Specification.new do |s|
  s.name = "vault"
  s.licenses    = ['MIT']
  s.version = Vault::VERSION
  s.default_executable = "vault"
  s.required_ruby_version = '~> 2.5'

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Christian Heimke"]
  s.date = %q{2018-05-01}
  s.description = %q{A simple tool to encrypt configuration files with templating support}
  s.email = %q{christian.heimke@loumaris.com}
  s.files = ["Gemfile", "lib/vault.rb", "lib/vault/version.rb", "bin/vault"]

  s.homepage = %q{https://github.com/dockerist/vault}
  s.metadata    = { "source_code_uri" => "https://github.com/dockerist/vault" }
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{vault!}

  s.executables << 'vault'

  s.add_runtime_dependency "gibberish", "~>2.1"
  s.add_runtime_dependency "slop", "~> 4.6"
end


