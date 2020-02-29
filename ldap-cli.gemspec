# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ldap/cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'ldap_cli'
  spec.version       = Ldap::Cli::VERSION
  spec.authors       = ['Naga Gangadhar']
  spec.email         = ['reddynagagangadhar@gmail.com']

  spec.summary       = 'Ldap::Cli for Ruby is reading/writing entries in a
    LDAP directory to/from CSV files'
  spec.description   = 'Ldap::Cli for Ruby is command-line interface tool
    for reading/writing entries in an LDAP directory to/from CSV files.'
  spec.homepage      = 'https://github.com/rngangadhar/ldap-cli'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org.
  # To allow pushes either set the "allowed_push_host" to allow pushing
  # to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'net-ldap', '~> 0.16.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.49.0'
end
