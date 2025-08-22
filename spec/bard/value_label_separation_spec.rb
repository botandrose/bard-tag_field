# frozen_string_literal: true

require "spec_helper"

RSpec.describe "bard_tag_field with value/label separation" do
  let(:template) { ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil) }
  let(:object) { TestModel.new }
  let(:form_builder) { ActionView::Helpers::FormBuilder.new(:test_model, object, template, {}) }

  before do
    # Ensure the FormBuilder includes our module
    ActionView::Helpers::FormBuilder.include Bard::TagField::FormBuilder
  end

  describe "value/label separation with choices" do
    context "when object has values that match choice values" do
      let(:choices) { [["JavaScript Framework", "js"], ["Python Web Framework", "py"], ["Ruby Framework", "rails"]] }

      before { object.tags = ["js", "rails"] }

      it "renders tag-option elements with values and corresponding labels" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="js">JavaScript Framework</tag-option>
            <tag-option value="rails">Ruby Framework</tag-option>
            <datalist>
              <option value="js">JavaScript Framework</option>
              <option value="py">Python Web Framework</option>
              <option value="rails">Ruby Framework</option>
            </datalist>
          </input-tag>
        HTML
      end

      it "shows proper display labels while storing submit values" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="js">JavaScript Framework</tag-option>
            <tag-option value="rails">Ruby Framework</tag-option>
            <datalist>
              <option value="js">JavaScript Framework</option>
              <option value="py">Python Web Framework</option>
              <option value="rails">Ruby Framework</option>
            </datalist>
          </input-tag>
        HTML
      end
    end

    context "when object has values that don't match choices" do
      let(:choices) { [["Ruby", "ruby"], ["Python", "python"]] }

      before { object.tags = ["javascript", "rails"] }

      it "renders tag-option elements with user values as both value and label" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="javascript">javascript</tag-option>
            <tag-option value="rails">rails</tag-option>
            <datalist>
              <option value="ruby">Ruby</option>
              <option value="python">Python</option>
            </datalist>
          </input-tag>
        HTML
      end
    end

    context "when object has mixed matching and non-matching values" do
      let(:choices) { [["Ruby Language", "ruby"], ["Python Language", "python"], ["JavaScript Language", "js"]] }

      before { object.tags = ["ruby", "custom_tag", "js"] }

      it "renders correct labels for matching choices and value-as-label for others" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="ruby">Ruby Language</tag-option>
            <tag-option value="custom_tag">custom_tag</tag-option>
            <tag-option value="js">JavaScript Language</tag-option>
            <datalist>
              <option value="ruby">Ruby Language</option>
              <option value="python">Python Language</option>
              <option value="js">JavaScript Language</option>
            </datalist>
          </input-tag>
        HTML
      end
    end

    context "with special characters in values and labels" do
      let(:choices) { [["C++ Programming", "cpp"], ["Node.js Framework", "nodejs"], ["C# Language", "csharp"]] }

      before { object.tags = ["cpp", "nodejs"] }

      it "properly escapes special characters in both values and labels" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="cpp">C++ Programming</tag-option>
            <tag-option value="nodejs">Node.js Framework</tag-option>
            <datalist>
              <option value="cpp">C++ Programming</option>
              <option value="nodejs">Node.js Framework</option>
              <option value="csharp">C# Language</option>
            </datalist>
          </input-tag>
        HTML
      end
    end

    context "with HTML-unsafe content" do
      let(:choices) { [["<Script>Tag</Script>", "script"], ["Safe & Sound", "safe"]] }

      before { object.tags = ["script", "<user_tag>"] }

      it "properly escapes HTML in both values and labels" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="script">&lt;Script&gt;Tag&lt;/Script&gt;</tag-option>
            <tag-option value="&lt;user_tag&gt;">&lt;user_tag&gt;</tag-option>
            <datalist>
              <option value="script">&lt;Script&gt;Tag&lt;/Script&gt;</option>
              <option value="safe">Safe &amp; Sound</option>
            </datalist>
          </input-tag>
        HTML
      end
    end
  end

  describe "backward compatibility" do
    context "with simple string choices (no nested arrays)" do
      let(:choices) { ["ruby", "python", "javascript"] }

      before { object.tags = ["ruby", "python"] }

      it "continues to work as before with value and label being the same" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="ruby">ruby</tag-option>
            <tag-option value="python">python</tag-option>
            <datalist>
              <option value="ruby">ruby</option>
              <option value="python">python</option>
              <option value="javascript">javascript</option>
            </datalist>
          </input-tag>
        HTML
      end
    end

    context "without choices parameter" do
      before { object.tags = ["tag1", "tag2"] }

      it "continues to work as before" do
        expect(form_builder.bard_tag_field(:tags)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="test_model_tags">
            <tag-option value="tag1">tag1</tag-option>
            <tag-option value="tag2">tag2</tag-option>
          </input-tag>
        HTML
      end
    end
  end

  describe "form integration scenarios" do
    context "simulating form submission with value/label separation" do
      let(:choices) { [["Ruby Programming Language", "ruby"], ["Python Programming", "py"], ["JavaScript", "js"]] }

      before { object.tags = ["ruby", "js"] }

      it "creates form that would submit values while displaying labels to user" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="ruby">Ruby Programming Language</tag-option>
            <tag-option value="js">JavaScript</tag-option>
            <datalist>
              <option value="ruby">Ruby Programming Language</option>
              <option value="py">Python Programming</option>
              <option value="js">JavaScript</option>
            </datalist>
          </input-tag>
        HTML
      end
    end
  end

  describe "choice lookup functionality" do
    let(:choices) { [["Display A", "val_a"], ["Display B", "val_b"], ["Display C", "val_c"]] }

    context "with single matching value" do
      before { object.tags = ["val_a"] }

      it "correctly maps value to display label" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="val_a">Display A</tag-option>
            <datalist>
              <option value="val_a">Display A</option>
              <option value="val_b">Display B</option>
              <option value="val_c">Display C</option>
            </datalist>
          </input-tag>
        HTML
      end
    end

    context "with multiple matching values" do
      before { object.tags = ["val_b", "val_c"] }

      it "correctly maps values to display labels" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="val_b">Display B</tag-option>
            <tag-option value="val_c">Display C</tag-option>
            <datalist>
              <option value="val_a">Display A</option>
              <option value="val_b">Display B</option>
              <option value="val_c">Display C</option>
            </datalist>
          </input-tag>
        HTML
      end
    end

    context "with mixed matching and unknown values" do
      before { object.tags = ["val_a", "unknown_value", "val_c"] }

      it "correctly maps matching values to labels and uses unknown values as-is" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="...">
            <tag-option value="val_a">Display A</tag-option>
            <tag-option value="unknown_value">unknown_value</tag-option>
            <tag-option value="val_c">Display C</tag-option>
            <datalist>
              <option value="val_a">Display A</option>
              <option value="val_b">Display B</option>
              <option value="val_c">Display C</option>
            </datalist>
          </input-tag>
        HTML
      end
    end
  end

  describe "empty and edge cases with value/label separation" do
    let(:choices) { [["Label", "value"]] }

    it "handles empty tags array" do
      object.tags = []
      expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
        <input-tag name="test_model[tags]" id="...">
          <datalist>
            <option value="value">Label</option>
          </datalist>
        </input-tag>
      HTML
    end

    it "handles nil tags" do
      object.tags = nil
      expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
        <input-tag name="test_model[tags]" id="...">
          <datalist>
            <option value="value">Label</option>
          </datalist>
        </input-tag>
      HTML
    end

    it "handles empty string tags" do
      object.tags = [""]
      expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
        <input-tag name="test_model[tags]" id="...">
          <tag-option value=""></tag-option>
          <datalist>
            <option value="value">Label</option>
          </datalist>
        </input-tag>
      HTML
    end
  end
end
