# frozen_string_literal: true

require "spec_helper"

RSpec.describe "tag_field autocomplete with value/label separation" do
  let(:template) { ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil) }
  let(:object) { TestModel.new }
  let(:form_builder) { ActionView::Helpers::FormBuilder.new(:test_model, object, template, {}) }

  before do
    ActionView::Helpers::FormBuilder.include Bard::TagField::FormBuilder
  end

  describe "datalist generation for autocomplete" do
    context "with nested array choices (value/label pairs)" do
      let(:choices) { [["JavaScript Framework", "js"], ["TypeScript Language", "ts"], ["Python Programming", "py"]] }

      before { object.tags = [] }

      it "connects input-tag to datalist properly" do
        expect(form_builder.tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags">
            <datalist>
              <option value="js">JavaScript Framework</option>
              <option value="ts">TypeScript Language</option>
              <option value="py">Python Programming</option>
            </datalist>
          </input-tag>
        HTML
      end
    end

    context "with mixed choice types" do
      let(:choices) { ["plain", ["Display Label", "value"], "another"] }

      it "generates correct datalist options for mixed types" do
        expect(form_builder.tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags">
            <datalist>
              <option value="plain">plain</option>
              <option value="value">Display Label</option>
              <option value="another">another</option>
            </datalist>
          </input-tag>
        HTML
      end
    end
  end
end
