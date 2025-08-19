# frozen_string_literal: true

require "spec_helper"

RSpec.describe "form.bard_tag_field" do
  let(:template) { ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil) }
  let(:object) { TestModel.new }
  let(:form_builder) { ActionView::Helpers::FormBuilder.new(:test_model, object, template, {}) }

  before do
    # Ensure the FormBuilder includes our module
    ActionView::Helpers::FormBuilder.include Bard::TagField::FormBuilder
  end

  describe "#bard_tag_field" do
    context "basic functionality" do
      it "returns HTML-safe string" do
        result = form_builder.bard_tag_field(:tags)
        expect(result).to be_a(String)
        expect(result).to be_html_safe
      end

      it "generates input-tag element" do
        expect(form_builder.bard_tag_field(:tags)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags"></input-tag>
        HTML
      end
    end

    context "with empty tags" do
      before { object.tags = [] }

      it "renders empty input-tag" do
        expect(form_builder.bard_tag_field(:tags)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags"></input-tag>
        HTML
      end
    end

    context "with single tag" do
      before { object.tags = ["ruby"] }

      it "renders input-tag with single tag-option" do
        expect(form_builder.bard_tag_field(:tags)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags">
            <tag-option value="ruby">ruby</tag-option>
          </input-tag>
        HTML
      end
    end

    context "with multiple tags" do
      before { object.tags = ["ruby", "rails", "javascript"] }

      it "renders input-tag with multiple tag-option elements" do
        expect(form_builder.bard_tag_field(:tags)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags">
            <tag-option value="ruby">ruby</tag-option>
            <tag-option value="rails">rails</tag-option>
            <tag-option value="javascript">javascript</tag-option>
          </input-tag>
        HTML
      end
    end

    context "with nil tags" do
      before { object.tags = nil }

      it "renders empty input-tag" do
        expect(form_builder.bard_tag_field(:tags)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags"></input-tag>
        HTML
      end
    end

    context "with string value instead of array" do
      before { object.single_tag = "single-value" }

      it "renders input-tag with single tag-option" do
        expect(form_builder.bard_tag_field(:single_tag)).to match_html(<<~HTML)
          <input-tag name="test_model[single_tag]" id="test_model_single_tag">
            <tag-option value="single-value">single-value</tag-option>
          </input-tag>
        HTML
      end
    end

    context "with HTML options" do
      it "accepts class option" do
        expect(form_builder.bard_tag_field(:tags, class: "custom-class")).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags" class="custom-class"></input-tag>
        HTML
      end

      it "accepts id option" do
        expect(form_builder.bard_tag_field(:tags, id: "custom-id")).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="custom-id"></input-tag>
        HTML
      end

      it "accepts data attributes" do
        expect(form_builder.bard_tag_field(:tags, data: { custom: "value" })).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags" data-custom="value"></input-tag>
        HTML
      end

      it "accepts multiple HTML options" do
        expect(form_builder.bard_tag_field(:tags,
          class: "form-control",
          id: "tag-field",
          data: { toggle: "tags" }
        )).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="tag-field" class="form-control" data-toggle="tags"></input-tag>
        HTML
      end
    end

    context "with block" do
      it "calls block with options" do
        block_called = false
        options_passed = nil

        form_builder.bard_tag_field(:tags) do |opts|
          block_called = true
          options_passed = opts
          "<custom-content></custom-content>".html_safe
        end

        expect(block_called).to be true
        expect(options_passed).to be_a(Hash)
      end

      it "uses block return value as content" do
        expect(form_builder.bard_tag_field(:tags) do |opts|
          "<custom-block-content></custom-block-content>".html_safe
        end).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags">
            <custom-block-content></custom-block-content>
          </input-tag>
        HTML
      end
    end

    context "name and id generation" do
      it "generates correct name attribute" do
        expect(form_builder.bard_tag_field(:tags)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags"></input-tag>
        HTML
      end

      it "generates correct id attribute" do
        expect(form_builder.bard_tag_field(:tags)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags"></input-tag>
        HTML
      end

      it "handles custom object name" do
        custom_builder = ActionView::Helpers::FormBuilder.new(:custom_model, object, template, {})
        custom_builder.extend(Bard::TagField::FormBuilder)

        expect(custom_builder.bard_tag_field(:tags)).to match_html(<<~HTML)
          <input-tag name="custom_model[tags]" id="custom_model_tags"></input-tag>
        HTML
      end
    end

    context "HTML escaping" do
      before { object.tags = ["<script>alert('xss')</script>", "safe&tag"] }

      it "properly escapes tag values" do
        expect(form_builder.bard_tag_field(:tags)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags">
            <tag-option value="&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;">&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</tag-option>
            <tag-option value="safe&amp;tag">safe&amp;tag</tag-option>
          </input-tag>
        HTML
      end

      it "properly escapes option values" do
        expect(form_builder.bard_tag_field(:tags, class: "<script>")).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags" class="&lt;script&gt;">
            <tag-option value="&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;">&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</tag-option>
            <tag-option value="safe&amp;tag">safe&amp;tag</tag-option>
          </input-tag>
        HTML
      end
    end

    context "with choices parameter (select-style syntax)" do
      context "with simple choices array" do
        let(:choices) { ["ruby", "rails", "javascript"] }

        it "renders datalist with option elements from choices array" do
          expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
            <input-tag name="test_model[tags]" id="..." list="..."></input-tag>
            <datalist id="...">
              <option value="ruby">ruby</option>
              <option value="rails">rails</option>
              <option value="javascript">javascript</option>
            </datalist>
          HTML
        end

        it "connects input-tag to datalist via list attribute" do
          expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
            <input-tag name="test_model[tags]" id="..." list="..."></input-tag>
            <datalist id="...">...</datalist>
          HTML
        end

        it "renders current object values as tag-option elements" do
          object.tags = ["rails"]
          expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
            <input-tag name="test_model[tags]" id="..." list="...">
              <tag-option value="rails">rails</tag-option>
            </input-tag>
            <datalist id="...">
              <option value="ruby">ruby</option>
              <option value="rails">rails</option>
              <option value="javascript">javascript</option>
            </datalist>
          HTML
        end
      end

      context "with nested array choices (display vs submit values)" do
        let(:choices) { [["Ruby Programming", "ruby"], ["Ruby on Rails", "rails"], ["JavaScript", "js"]] }

        it "renders datalist with correct display and submit values" do
          expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
            <input-tag name="test_model[tags]" id="..." list="..."></input-tag>
            <datalist id="...">
              <option value="ruby">Ruby Programming</option>
              <option value="rails">Ruby on Rails</option>
              <option value="js">JavaScript</option>
            </datalist>
          HTML
        end

        it "renders current object values as tag-option elements with corresponding display labels" do
          object.tags = ["rails", "js"]
          expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
            <input-tag name="test_model[tags]" id="..." list="...">
              <tag-option value="rails">Ruby on Rails</tag-option>
              <tag-option value="js">JavaScript</tag-option>
            </input-tag>
            <datalist id="...">
              <option value="ruby">Ruby Programming</option>
              <option value="rails">Ruby on Rails</option>
              <option value="js">JavaScript</option>
            </datalist>
          HTML
        end
      end

      context "with mixed choice formats" do
        let(:choices) { ["plain", ["Display Text", "value"], "another_plain"] }

        it "handles mixed array and string choices in datalist" do
          expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
            <input-tag name="test_model[tags]" id="..." list="..."></input-tag>
            <datalist id="...">
              <option value="plain">plain</option>
              <option value="value">Display Text</option>
              <option value="another_plain">another_plain</option>
            </datalist>
          HTML
        end
      end

      context "with choices and HTML options" do
        let(:choices) { [["Ruby", "ruby"], ["Rails", "rails"]] }

        it "accepts choices with HTML options" do
          expect(form_builder.bard_tag_field(:tags, choices, class: "custom-class")).to match_html(<<~HTML)
            <input-tag name="test_model[tags]" id="..." class="custom-class" list="..."></input-tag>
            <datalist id="...">
              <option value="ruby">Ruby</option>
              <option value="rails">Rails</option>
            </datalist>
          HTML
        end
      end

      context "with empty choices" do
        it "renders empty input-tag with empty array" do
          expect(form_builder.bard_tag_field(:tags, [])).to match_html(<<~HTML)
            <input-tag name="test_model[tags]" id="test_model_tags"></input-tag>
          HTML
        end

        it "renders empty input-tag with nil choices" do
          expect(form_builder.bard_tag_field(:tags, nil)).to match_html(<<~HTML)
            <input-tag name="test_model[tags]" id="test_model_tags"></input-tag>
          HTML
        end
      end

      context "with choices and block" do
        let(:choices) { [["Ruby", "ruby"], ["Rails", "rails"]] }

        it "calls block instead of using choices when block provided" do
          expect(form_builder.bard_tag_field(:tags, choices) do |opts|
            "<custom-block-content></custom-block-content>".html_safe
          end).to match_html(<<~HTML)
            <input-tag name="test_model[tags]" id="test_model_tags">
              <custom-block-content></custom-block-content>
            </input-tag>
          HTML
        end
      end
    end

    context "similarity to form.select" do
      it "accepts similar method signature with choices" do
        # Should work like: form.select(:tags, choices, options, html_options)
        expect {
          form_builder.bard_tag_field(:tags, ["ruby", "rails"], { class: "form-control" })
        }.not_to raise_error
      end

      it "accepts nested array choices like form.select" do
        expect {
          form_builder.bard_tag_field(:tags, [["Ruby", "ruby"], ["Rails", "rails"]])
        }.not_to raise_error
      end

      it "accepts block like form.select" do
        expect {
          form_builder.bard_tag_field(:tags) do |opts|
            "<custom-content></custom-content>".html_safe
          end
        }.not_to raise_error
      end
    end

    context "edge cases with choices" do
      it "handles choices with HTML characters in display text" do
        choices = [["<Ruby> & Rails", "ruby_rails"], ["C++", "cpp"]]
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="..." list="..."></input-tag>
          <datalist id="...">
            <option value="ruby_rails">&lt;Ruby&gt; &amp; Rails</option>
            <option value="cpp">C++</option>
          </datalist>
        HTML
      end

      it "handles choices with special characters in values" do
        choices = [["Ruby", "ruby-lang"], ["C#", "c_sharp"], ["Node.js", "node.js"]]
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="..." list="..."></input-tag>
          <datalist id="...">
            <option value="ruby-lang">Ruby</option>
            <option value="c_sharp">C#</option>
            <option value="node.js">Node.js</option>
          </datalist>
        HTML
      end

      it "handles nested arrays with more than 2 elements" do
        # Should only use first 2 elements [display, value] and ignore the rest
        choices = [["Display", "value", "extra", "ignored"]]
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="..." list="..."></input-tag>
          <datalist id="...">
            <option value="value">Display</option>
          </datalist>
        HTML
      end

      it "handles deeply nested arrays gracefully" do
        choices = [["Top Level", ["nested", "ignored"]]]
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="..." list="..."></input-tag>
          <datalist id="...">
            <option value="nested ignored">Top Level</option>
          </datalist>
        HTML
      end

      it "renders object values as tag-options when choices provided but empty" do
        object.tags = ["existing", "tags"]
        expect(form_builder.bard_tag_field(:tags, [])).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags">
            <tag-option value="existing">existing</tag-option>
            <tag-option value="tags">tags</tag-option>
          </input-tag>
        HTML
      end
    end
  end
end
