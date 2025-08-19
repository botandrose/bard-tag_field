# frozen_string_literal: true

require_relative "tag_field/version"
require_relative "tag_field/form_builder"

module Bard
  module TagField
    class Engine < ::Rails::Engine
      initializer "bard-tag_field.assets" do
        if Rails.application.config.respond_to?(:assets)
          Rails.application.config.assets.precompile += ["input-tag.js"]
        end
      end

      config.after_initialize do
        ActionView::Base.default_form_builder.include FormBuilder
      end
    end
  end
end
