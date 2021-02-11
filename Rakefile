require 'bundler/gem_tasks'
require 'ci/reporter/rake/rspec'
require 'rspec/core/rake_task'

namespace :ci do
  RSpec::Core::RakeTask.new(:all => ['ci:setup:rspec']) do |t|
    t.pattern = '**/*_spec.rb'
  end
end
