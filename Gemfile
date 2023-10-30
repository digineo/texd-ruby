# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "pry-byebug"
gem "rails", "~> 7.0"

gem "yard", group: :docs

group :development do
  gem "rubocop"
  gem "rubocop-rails"
  gem "rubocop-rake"
  gem "rubocop-rspec"
end

# keep in sync with gemfiles/*/Gemfile
group :development, :test do
  gem "combustion"
  gem "rake", "~> 13.1"
  gem "rspec", "~> 3.0"
  gem "rspec-rails"
end
