# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Build JavaScript assets"
task :build_js do
  sh "cd input-tag && npm run build"
end

desc "Install npm dependencies"
task :install_deps do
  sh "cd input-tag && npm install"
end
