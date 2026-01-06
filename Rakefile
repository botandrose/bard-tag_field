# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "cucumber/rake/task"

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:cucumber)

task default: [:spec, :cucumber]

task build: :build_js

desc "Build JavaScript assets"
task :build_js do
  sh "cd input-tag && bun run build"
  cp "input-tag/dist/input-tag.js", "app/assets/javascripts/input-tag.js"
end

desc "Install bun dependencies"
task :install_deps do
  sh "cd input-tag && bun install"
end
