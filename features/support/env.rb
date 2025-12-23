require "bundler/setup"
require "capybara/cucumber"
require "capybara/cuprite"
require "chop"

# Build input-tag JS before running tests
require "rake"
load File.expand_path("../../Rakefile", __dir__)
Rake::Task["build_js"].invoke

require_relative "test_app"
require "bard/tag_field/cucumber"

Capybara.register_driver :cuprite do |app|
  options = {
    window_size: [1200, 800],
    headless: true,
    process_timeout: 60,
    timeout: 30
  }

  # Support custom browser path for CI
  if ENV["BROWSER_PATH"] && !ENV["BROWSER_PATH"].empty?
    options[:browser_path] = ENV["BROWSER_PATH"]
  elsif ENV["CI"]
    # On GitHub Actions, use google-chrome which is pre-installed
    options[:browser_path] = "/usr/bin/google-chrome"
  end

  Capybara::Cuprite::Driver.new(app, **options)
end

Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite
Capybara.app = Rails.application
