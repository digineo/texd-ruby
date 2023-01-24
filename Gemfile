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

eval File.read File.join(__dir__, "gemfiles/common.rb") # rubocop:disable Security/Eval
