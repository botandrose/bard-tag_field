# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "cucumber/rake/task"

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:cucumber)

task default: [:spec, :cucumber]

desc "Build JavaScript assets"
task :build_js do
  sh "cd input-tag && bun run build"
end

desc "Install bun dependencies"
task :install_deps do
  sh "cd input-tag && bun install"
end
