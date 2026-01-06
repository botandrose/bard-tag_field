require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "bard/tag_field"

class TestApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new("/dev/null")
  config.secret_key_base = "test_secret_key_base_for_testing_only"
  config.hosts.clear
end

# Model
class Item
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :tags, default: -> { [] }

  def tags=(value)
    super Array(value).reject(&:blank?)
  end

  def persisted?
    false
  end
end

class CoursesItem
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :course_ids, default: -> { [] }

  def course_ids=(value)
    super Array(value).reject(&:blank?)
  end

  def persisted?
    false
  end
end

# Controller
class ItemsController < ActionController::Base
  def new
    @item = Item.new(tags: params[:tags] || [])
    render inline: <<~ERB, layout: false
      <!DOCTYPE html>
      <html>
      <head>
        <script src="/input-tag.js"></script>
      </head>
      <body>
        <%= form_with model: @item, url: "/items", method: :post do |f| %>
          <label for="item_tags">Tags</label>
          <%= f.tag_field :tags, multiple: true, id: "item_tags" %>
          <%= f.submit "Save" %>
        <% end %>
      </body>
      </html>
    ERB
  end

  def create
    @item = Item.new(params.require(:item).permit(tags: []))
    render inline: <<~ERB, layout: false
      <!DOCTYPE html>
      <html>
      <body>
        <div id="submitted-params"><%= params.permit!.to_h.to_json %></div>
        <div id="model-attributes"><%= { tags: @item.tags }.to_json %></div>
      </body>
      </html>
    ERB
  end
end

# Controller for testing datalist label-to-value resolution
class CoursesItemsController < ActionController::Base
  COURSES = [
    ["English Basics", "1"],
    ["Algebra I", "2"],
    ["World History", "3"],
  ]

  def new
    @courses_item = CoursesItem.new(course_ids: params[:course_ids] || [])
    @courses = COURSES
    render inline: <<~ERB, layout: false
      <!DOCTYPE html>
      <html>
      <head>
        <script src="/input-tag.js"></script>
      </head>
      <body>
        <%= form_with model: @courses_item, url: "/courses_items", method: :post do |f| %>
          <label for="courses_item_course_ids">Courses</label>
          <%= f.tag_field :course_ids, @courses, multiple: true, id: "courses_item_course_ids" %>
          <%= f.submit "Save" %>
        <% end %>
      </body>
      </html>
    ERB
  end

  def create
    @courses_item = CoursesItem.new(params.require(:courses_item).permit(course_ids: []))
    render inline: <<~ERB, layout: false
      <!DOCTYPE html>
      <html>
      <body>
        <div id="submitted-params"><%= params.permit!.to_h.to_json %></div>
        <div id="model-attributes"><%= { course_ids: @courses_item.course_ids }.to_json %></div>
      </body>
      </html>
    ERB
  end
end

# Serve input-tag.js from gem assets
class AssetsController < ActionController::Base
  def input_tag_js
    js_path = File.expand_path("../../app/assets/javascripts/input-tag.js", __dir__)
    send_file js_path, type: "application/javascript", disposition: "inline"
  end
end

TestApp.initialize!

Rails.application.routes.draw do
  resources :items, only: [:new, :create]
  resources :courses_items, only: [:new, :create]
  get "/input-tag.js", to: "assets#input_tag_js"
end
