# frozen_string_literal: true

require "rails"
require "action_view"
require "active_model"
require "bard/tag_field"
require "equivalent-xml"
require "rspec/matchers"

# Mock Rails application for testing
class TestApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new(nil)
end

TestApp.initialize!

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Include ActionView test helpers
  config.include ActionView::Helpers
  config.include ActionView::Context

  # Helper method for creating form builder instances
  config.before(:each) do
    @template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    @object = OpenStruct.new
  end
end

# Test model for form binding
class TestModel
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :tags, default: []
  attribute :single_tag, :string

  def persisted?
    false
  end
end

# Custom RSpec matcher for HTML with wildcard support
RSpec::Matchers.define :match_html do |expected|
  match do |actual|
    compare_html_with_wildcards(actual, expected)
  end

  failure_message do |actual|
    "Expected HTML to match pattern with wildcards:\n#{expected}\n\nActual HTML:\n#{actual}\n\nDifferences:\n#{@diff_message}"
  end

  def compare_html_with_wildcards(actual_html, expected_html)
    # Parse both HTML fragments
    actual_doc = Nokogiri::HTML::DocumentFragment.parse(actual_html.to_s)
    expected_doc = Nokogiri::HTML::DocumentFragment.parse(expected_html.to_s)

    # Filter out whitespace-only text nodes
    actual_children = actual_doc.children.reject { |node| node.text? && node.text.strip.empty? }
    expected_children = expected_doc.children.reject { |node| node.text? && node.text.strip.empty? }

    # Compare each element
    compare_elements(actual_children, expected_children)
  end

  def compare_elements(actual_nodes, expected_nodes)
    # Filter out whitespace-only text nodes for both collections
    actual_filtered = actual_nodes.reject { |node| node.text? && node.text.strip.empty? }
    expected_filtered = expected_nodes.reject { |node| node.text? && node.text.strip.empty? }

    # Handle the case where expected has wildcard content (...)
    if expected_filtered.size == 1 && expected_filtered.first.text? && expected_filtered.first.text.strip == "..."
      return true
    end

    return false if actual_filtered.size != expected_filtered.size

    actual_filtered.zip(expected_filtered).all? do |actual_node, expected_node|
      compare_single_element(actual_node, expected_node)
    end
  end

  def compare_single_element(actual, expected)
    # Skip text node comparison for whitespace-only nodes
    if actual.text? && expected.text?
      return actual.text.strip == expected.text.strip
    end

    # Must be same type (both elements, both text, etc)
    return false if actual.class != expected.class

    # Skip non-element nodes we don't care about
    return true unless actual.element?

    # Compare element names
    return false if actual.name != expected.name

    # Compare attributes with wildcard support
    return false unless compare_attributes(actual, expected)

    # Compare children with wildcard support
    if expected.children.size == 1 && expected.children.first.text? &&
       expected.children.first.text.strip == "..."
      # Wildcard content - don't compare children
      return true
    else
      # Compare children recursively
      return compare_elements(actual.children, expected.children)
    end
  end

  def compare_attributes(actual, expected)
    expected_attrs = expected.attributes
    actual_attrs = actual.attributes

    # Handle wildcard attributes (... at end of attribute list)
    has_wildcard = expected_attrs.key?("...")
    expected_attrs = expected_attrs.reject { |k, v| k == "..." } if has_wildcard

    # Check all expected attributes are present
    expected_attrs.each do |name, expected_attr|
      actual_attr = actual_attrs[name]
      return false unless actual_attr

      # Handle wildcard attribute values
      if expected_attr.value == "..."
        # Any value is acceptable
        next
      else
        return false if actual_attr.value != expected_attr.value
      end
    end

    # If no wildcard, actual must not have extra attributes
    unless has_wildcard
      return false if actual_attrs.keys.size != expected_attrs.keys.size
    end

    true
  end
end
