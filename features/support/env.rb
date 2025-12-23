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
    process_timeout: 30,
    timeout: 30
  }

  # Support custom browser path for CI (e.g., Playwright's chromium)
  if ENV["BROWSER_PATH"]
    browser_path = Dir.glob(ENV["BROWSER_PATH"]).first
    options[:browser_path] = browser_path if browser_path
  end

  Capybara::Cuprite::Driver.new(app, **options)
end

Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite
Capybara.app = Rails.application
