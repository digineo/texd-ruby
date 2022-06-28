# frozen_string_literal: true

require "bundler/gem_tasks"
Bundler.require(:development)

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new

  task default: %i[spec rubocop]
rescue LoadError
  # we're likely running `make test`
  task default: :spec # rubocop:disable Rake/DuplicateTask
end
