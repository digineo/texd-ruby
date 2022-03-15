# frozen_string_literal: true

require_relative "lib/texd/version"

Gem::Specification.new do |spec|
  spec.name    = "texd"
  spec.version = Texd::VERSION
  spec.authors = ["Dominik Menke"]
  spec.email   = ["dom@digineo.de"]

  spec.summary     = "texd is a Ruby client for the texd web service."
  spec.description = "The texd project provides a network reachable TeX compiler. This gem is a client for that."
  spec.homepage    = "https://github.com/digineo/texd-ruby"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = spec.homepage
  spec.metadata["changelog_uri"]         = "#{spec.homepage}/blob/v#{Texd::VERSION}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) {
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  }

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "multipart-post", "~> 2.0"
  spec.add_dependency "rails", ">= 6.0", "< 8"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-rspec"
end
