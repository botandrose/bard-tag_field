require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "bard/tag_field"

class DemoApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new($stdout)
  config.secret_key_base = "demo_secret_key_base_not_for_production_use"
  config.action_controller.default_protect_from_forgery = false
  config.hosts.clear
  config.consider_all_requests_local = true
end

# Transient in-memory store. Resets to {} every time the process restarts.
STORE = {}

class Post
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :tags, default: -> { [] }
  attribute :categories, default: -> { [] }

  def tags=(value)
    super Array(value).reject(&:blank?)
  end

  def categories=(value)
    super Array(value).reject(&:blank?)
  end

  def persisted? = false
end

CATEGORY_CHOICES = [
  ["Web Development", "web-dev"],
  ["Machine Learning", "ml"],
  ["Database Design", "db"],
  ["DevOps", "devops"],
]

LANGUAGE_CHOICES = ["ruby", "rails", "javascript", "css", "python", "go"]

class DemoController < ActionController::Base
  def index
    saved = STORE[:post]
    @post = Post.new(
      tags: saved&.tags || ["rails", "ruby"],
      categories: saved&.categories || ["web-dev"],
    )
    @saved = saved
    render inline: TEMPLATE, layout: false
  end

  def create
    STORE[:post] = Post.new(params.require(:post).permit(tags: [], categories: []))
    redirect_to "/"
  end

  TEMPLATE = <<~ERB
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>bard-tag_field demo</title>
      <script src="/input-tag.js"></script>
      <style>
        body { font-family: -apple-system, system-ui, sans-serif; max-width: 820px; margin: 2rem auto; padding: 0 1rem; line-height: 1.5; color: #222; }
        h1 { color: #2c3e50; }
        section { border-left: 3px solid #e9ecef; padding-left: 1rem; margin: 1.75rem 0; }
        h2 { color: #34495e; font-size: 1.05rem; margin-bottom: .25rem; }
        small { color: #888; }
        code { background: #f4f4f4; padding: 1px 4px; border-radius: 3px; font-size: .85em; }
        input-tag { display: block; margin: .5rem 0; max-width: 520px; }
        .themed {
          --tag-option-bg: #1f6feb;
          --container-border: #ccd;
          --container-border-left-width: 3px;
          --container-border-left-color: #1f6feb;
        }
        .saved { background: #f8fff9; border: 1px solid #cde; border-left: 3px solid #28a745; padding: .5rem .75rem; border-radius: 4px; }
        button { margin-top: .5rem; }
      </style>
    </head>
    <body>
      <h1>🏷️ bard-tag_field demo</h1>
      <p>Every <code>tag_field</code> signature, rendered by the gem. State is in-memory and transient &mdash; restart the server to reset.</p>

      <% if @saved %>
        <section class="saved">
          <h2>✅ Last saved (lives until restart)</h2>
          <p>tags: <strong><%= @saved.tags.inspect %></strong><br>
             categories: <strong><%= @saved.categories.inspect %></strong></p>
        </section>
      <% end %>

      <section>
        <h2>1. Live round-trip &mdash; saved to in-memory store</h2>
        <small>Basic field (pre-populated from the model) + nested <code>[display, value]</code> choices. Submit, then watch the banner above; restart the server to reset.</small>
        <%= form_with model: @post, url: "/", method: :post do |form| %>
          <p><label>Tags (free-form)</label><br>
          <%= form.tag_field :tags, multiple: true %></p>
          <p><label>Categories (submits values, displays labels)</label><br>
          <%= form.tag_field :categories, CATEGORY_CHOICES, { multiple: true } %></p>
          <button type="submit">Save</button>
        <% end %>
      </section>

      <section>
        <h2>2. Simple string choices (datalist autocomplete)</h2>
        <small><code>form.tag_field :tags, LANGUAGE_CHOICES, { multiple: true }</code> &mdash; type to autocomplete</small>
        <%= form_with model: @post, url: "#", method: :get do |form| %>
          <%= form.tag_field :tags, LANGUAGE_CHOICES, { multiple: true, id: "demo_choices" } %>
        <% end %>
      </section>

      <section>
        <h2>3. HTML options + CSS-variable theming</h2>
        <small>Same choices field, themed via <code>--tag-option-bg</code> and a left accent stripe</small>
        <%= form_with model: @post, url: "#", method: :get do |form| %>
          <%= form.tag_field :tags, LANGUAGE_CHOICES, { multiple: true, id: "demo_themed", class: "themed" } %>
        <% end %>
      </section>

      <section>
        <h2>4. Block-based custom rendering</h2>
        <small><code>form.tag_field(:tags) { |options| ... }</code> &mdash; renders the block's own tag-option markup</small>
        <%= form_with model: @post, url: "#", method: :get do |form| %>
          <%= form.tag_field :tags, { multiple: true, id: "demo_block" } do |options| %>
            <% @post.tags.each do |tag| %>
              <tag-option value="<%= tag %>">#<%= tag %></tag-option>
            <% end %>
          <% end %>
        <% end %>
      </section>
    </body>
    </html>
  ERB
end

class AssetsController < ActionController::Base
  def input_tag_js
    path = File.expand_path("app/assets/javascripts/input-tag.js", __dir__)
    send_file path, type: "application/javascript", disposition: "inline"
  end
end

DemoApp.initialize!

Rails.application.routes.draw do
  root "demo#index"
  post "/", to: "demo#create"
  get "/input-tag.js", to: "assets#input_tag_js"
end

run Rails.application
