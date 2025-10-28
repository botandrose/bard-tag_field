# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails form helper gem that provides `tag_field` for creating interactive tag input fields. The gem wraps the [@botandrose/input-tag](https://github.com/botandrose/input-tag) custom element and integrates it with Rails form builders.

**Key Architecture:**
- `lib/bard/tag_field/form_builder.rb` - Rails form builder integration that handles method signature variants (like Rails' `select` helper)
- `lib/bard/tag_field/field.rb` - Core field rendering logic, extends `ActionView::Helpers::Tags::TextField`
- `lib/bard/tag_field.rb` - Rails Engine that auto-registers the form builder and precompiles JavaScript assets
- `input-tag/` - JavaScript build directory using Rollup to bundle the `@botandrose/input-tag` package with Bun
- `app/assets/javascripts/input-tag.js` - Compiled JavaScript output for Rails asset pipeline

## Development Commands

### Testing
```bash
# Run all tests
bundle exec rspec

# Run tests for specific Rails version
bundle exec appraisal rails-7.1 rspec
bundle exec appraisal rails-7.2 rspec
bundle exec appraisal rails-8.0 rspec

# Generate appraisal gemfiles after updating Appraisals
bundle exec appraisal install
```

### JavaScript Assets
```bash
# Build JavaScript assets (required before running tests or releasing)
cd input-tag && bun run build

# Install Bun dependencies
cd input-tag && bun install

# Clean compiled assets
cd input-tag && bun run clean
```

### Gem Management
```bash
# Install the gem locally for testing
bundle exec rake install

# Build gem package
bundle exec rake build
```

## Form Builder Method Signatures

The `tag_field` method supports multiple signatures to match Rails conventions:

```ruby
# Basic usage
form.tag_field :tags

# With HTML options only
form.tag_field :tags, class: "form-control"

# With choices (like form.select)
form.tag_field :tags, ["ruby", "rails", "javascript"]

# With choices and HTML options
form.tag_field :tags, ["ruby", "rails"], {}, { class: "form-control" }

# With nested choices [display, value]
form.tag_field :categories, [["Web Dev", "web"], ["ML", "ml"]]

# With block for custom rendering
form.tag_field :tags do |options|
  # Custom tag-option rendering
end
```

The FormBuilder handles signature detection in lib/bard/tag_field/form_builder.rb:6-21.

## Rendering Logic

The Field class (lib/bard/tag_field/field.rb) handles three rendering scenarios:

1. **Object values only** - Renders current object's tags as `<tag-option>` elements
2. **With choices** - Renders object values as `<tag-option>` and choices in a nested `<datalist>`
3. **With block** - Delegates content rendering to the provided block

The `build_choice_map` method (lib/bard/tag_field/field.rb:58-74) maps choice values to display labels for proper tag rendering.

## Testing

Tests use RSpec with a custom HTML matcher that supports wildcards (`...`) for flexible HTML comparison. The matcher is defined in spec/spec_helper.rb:55-152 and allows testing HTML structure without exact whitespace or attribute order matching.

Test setup includes a mock Rails application (TestApp) initialized in spec/spec_helper.rb:12-17.

## JavaScript Build Process

The gem bundles the `@botandrose/input-tag` package using Rollup with Bun:
1. Source: `input-tag/index.js` imports from `@botandrose/input-tag`
2. Build: `cd input-tag && bun run build` runs Rollup
3. Output: `app/assets/javascripts/input-tag.js` for Rails asset pipeline
4. The Engine precompiles this asset (lib/bard/tag_field.rb:11)

**Important:** Always rebuild JavaScript assets after updating the `@botandrose/input-tag` dependency.

## Multi-Rails Version Support

Uses Appraisal gem to test against Rails 7.1, 7.2, and 8.0. Gemfiles are in `gemfiles/` directory. CI tests all combinations of Ruby 3.2/3.3/3.4 with each Rails version.
