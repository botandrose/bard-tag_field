# frozen_string_literal: true

require_relative "lib/bard/tag_field/version"

Gem::Specification.new do |spec|
  spec.name = "bard-tag_field"
  spec.version = Bard::TagField::VERSION
  spec.authors = ["Micah Geisel"]
  spec.email = ["micah@botandrose.com"]

  spec.summary = "form.tag_field using @botandrose/input-tag custom element"
  spec.description  = "form.tag_field using @botandrose/input-tag custom element"
  spec.homepage = "https://github.com/botandrose/bard-tag_field"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.1"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "equivalent-xml"
  spec.add_development_dependency "appraisal"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
