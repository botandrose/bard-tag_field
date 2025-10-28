# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Build JavaScript assets"
task :build_js do
  sh "cd input-tag && bun run build"
end

desc "Install Bun dependencies"
task :install_deps do
  sh "cd input-tag && bun install"
end
