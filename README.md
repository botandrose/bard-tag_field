# Bard::TagField

[![CI Status](https://github.com/botandrose/bard-tag_field/workflows/CI/badge.svg)](https://github.com/botandrose/bard-tag_field/actions)
[![Ruby](https://img.shields.io/badge/ruby-3.2%2B-red)](https://www.ruby-lang.org)
[![Rails](https://img.shields.io/badge/rails-7.1%2B-red)](https://rubyonrails.org)

A Rails form helper gem that adds `tag_field` to your forms, creating interactive tag input fields using the [@botandrose/input-tag](https://github.com/botandrose/input-tag) custom element.

Perfect for adding tag functionality to your Rails forms with a clean, modern interface that works seamlessly with your existing Rails form helpers.

## Features

- 🏷️ **Interactive tag input** - Users can add/remove tags dynamically
- 🔧 **Rails integration** - Works like any other Rails form helper (`form.select`, `form.text_field`, etc.)
- 🎨 **Customizable** - Supports all standard HTML options (class, id, data attributes)
- 🛡️ **Secure** - Automatic HTML escaping prevents XSS attacks
- 🧪 **Well-tested** - Comprehensive test suite
- ⚡ **Modern** - Built with custom web elements
- 🔄 **Compatible** - Supports Ruby 3.2+ and Rails 7.1+

## Usage

### Basic Usage

After installing and requiring the gem, Use `tag_field` in your Rails forms just like any other form helper:

```erb
<%= form_with model: @post do |form| %>
  <%= form.tag_field :tags %>
<% end %>
```

This generates an interactive tag field that binds to your model's `tags` attribute.

### With HTML Options

Add CSS classes, data attributes, and other HTML options:

```erb
<%= form.tag_field :tags,
    class: "form-control",
    id: "post-tags",
    data: { placeholder: "Add tags..." } %>
```

### With Existing Tags

The field automatically displays existing tags from your model:

```ruby
# In your controller
@post.tags = ["rails", "ruby", "web-development"]
```

```erb
<!-- Tags will be pre-populated in the form -->
<%= form.tag_field :tags %>
```

### With Predefined Choices (Rails select-style)

Like `form.select`, you can provide predefined choices for users to select from:

```erb
<%= form.tag_field :tags, ["ruby", "rails", "javascript", "css"] %>
```

Or use nested arrays for display vs submit values:

```erb
<%= form.tag_field :categories, [
  ["Web Development", "web-dev"],
  ["Machine Learning", "ml"],
  ["Database Design", "db"]
] %>
```

This creates a datalist with available options while still showing current object values as selected tags.

### Custom Content with Blocks

Use blocks for custom tag rendering:

```erb
<%= form.tag_field :tags do |options| %>
  <% @post.tags.each do |tag| %>
    <tag-option value="<%= tag %>" class="custom-tag"><%= tag %></tag-option>
  <% end %>
<% end %>
```

## Model Setup

Your model should handle tags as an array. Here are common approaches:

### With Array Attribute (Rails 5+)

```ruby
class Post < ApplicationRecord
  # In migration: add_column :posts, :tags, :text, array: true, default: []
  # Or use JSON column: add_column :posts, :tags, :json, default: []
end
```

### With Serialization

```ruby
class Post < ApplicationRecord
  serialize :tags, Array
end
```

### With ActsAsTaggable

```ruby
class Post < ApplicationRecord
  acts_as_taggable_on :tags

  # Helper method for form binding
  def tags_array
    tag_list.to_a
  end

  def tags_array=(values)
    self.tag_list = values
  end
end
```

```erb
<%= form.tag_field :tags_array %>
```

## Generated HTML

The gem generates semantic HTML using custom elements:

```html
<!-- With current object values -->
<input-tag name="post[tags]" id="post_tags">
  <tag-option value="rails">rails</tag-option>
  <tag-option value="ruby">ruby</tag-option>
</input-tag>

<!-- With choices parameter -->
<input-tag name="post[tags]" id="post_tags" list="post_tags_datalist">
  <tag-option value="rails">rails</tag-option>
</input-tag>
<datalist id="post_tags_datalist">
  <option value="ruby">ruby</option>
  <option value="javascript">javascript</option>
  <option value="css">css</option>
</datalist>
```

## JavaScript Integration

This gem works with the [@botandrose/input-tag](https://github.com/botandrose/input-tag) custom element.

```javascript
// In your application.js or wherever you manage JS
import '@botandrose/input-tag'
```

Or include the precompiled asset (automatically added by this gem):

```javascript
//= require input-tag
```

## Browser Support

- Modern browsers that support custom elements
- Graceful degradation for older browsers
- Supports Ruby 3.2+ and Rails 7.1+ (including Rails 8.0)

## API Reference

### `tag_field(method, choices = nil, options = {}, html_options = {}, &block)`

**Parameters:**
- `method` - The attribute name (symbol)
- `choices` - Optional array of predefined choices (like `form.select`)
- `options` - Hash of Rails form options
- `html_options` - Hash of HTML attributes (class, id, data, etc.)
- `&block` - Optional block for custom content rendering

**Returns:** HTML-safe string containing the tag input element

**Examples:**
```ruby
# Basic usage
form.tag_field :tags

# With choices
form.tag_field :tags, ["ruby", "rails", "javascript"]

# With nested choices (display vs value)
form.tag_field :categories, [["Web Dev", "web"], ["ML", "ml"]]

# With HTML options
form.tag_field :tags, class: "form-control", data: { max_tags: 5 }

# With choices and HTML options
form.tag_field :tags, ["ruby", "rails"], {}, { class: "form-control" }
```

## Cucumber & Chop Integration

This gem provides a [Chop](https://github.com/botandrose/chop) form field integration so that `tag_field` inputs work seamlessly with `table.fill_in!` in your Cucumber scenarios.

### Setup

Require the integration in your Cucumber support files:

```ruby
# features/support/env.rb
require "chop"
require "bard/tag_field/cucumber"
```

### Filling in Tag Fields with Chop

Once loaded, `table.fill_in!` works with tag fields just like any other form field:

```gherkin
When I fill in the following:
  | Tags | ruby, rails, javascript |
```

When the tag field has a datalist (predefined choices with display labels), Chop automatically resolves display labels to their submit values:

```gherkin
# If the datalist has options like ["English Basics", "1"], ["Algebra I", "2"]
When I fill in the following:
  | Courses | English Basics, Algebra I |
# Submits values "1" and "2"
```

Unknown values are passed through as-is:

```gherkin
When I fill in the following:
  | Courses | English Basics, Custom Course |
# Submits "1" and "Custom Course"
```

### Additional Step Definitions

The integration also provides these step definitions for more granular interaction:

```gherkin
# Type into a tag field via keyboard
When I fill in the "Tags" tag field with "ruby"

# Remove a specific tag
When I remove "rails" from the "Tags" tag field

# Assert the current tags
Then I should see the following "Tags" tag field:
  | ruby | rails |

# Assert a tag field is empty
Then I should see an empty "Tags" tag field

# Assert available datalist options
Then I should see the following "Courses" available tag options:
  | English Basics |
  | Algebra I      |
  | World History  |

# Assert visible autocomplete suggestions
Then I should see the following "Tags" tag field autocomplete options:
  | ruby  |
  | rails |
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/botandrose/bard-tag_field.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

Created by [Micah Geisel](https://github.com/micahgeisel) at [Bot & Rose](https://github.com/botandrose).
