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
          <input-tag name="test_model[tags]" id="..." list="...">
            <tag-option value="js">JavaScript Framework</tag-option>
            <tag-option value="rails">Ruby Framework</tag-option>
          </input-tag>
          <datalist id="...">
            <option value="js">JavaScript Framework</option>
            <option value="py">Python Web Framework</option>
            <option value="rails">Ruby Framework</option>
          </datalist>
        HTML
      end

      it "shows proper display labels while storing submit values" do
        # Verify that the form would store values but display labels
        result = form_builder.bard_tag_field(:tags, choices)
        expect(result).to include('value="js">JavaScript Framework')
        expect(result).to include('value="rails">Ruby Framework')
      end
    end

    context "when object has values that don't match choices" do
      let(:choices) { [["Ruby", "ruby"], ["Python", "python"]] }

      before { object.tags = ["javascript", "rails"] }

      it "renders tag-option elements with user values as both value and label" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="..." list="...">
            <tag-option value="javascript">javascript</tag-option>
            <tag-option value="rails">rails</tag-option>
          </input-tag>
          <datalist id="...">
            <option value="ruby">Ruby</option>
            <option value="python">Python</option>
          </datalist>
        HTML
      end
    end

    context "when object has mixed matching and non-matching values" do
      let(:choices) { [["Ruby Language", "ruby"], ["Python Language", "python"], ["JavaScript Language", "js"]] }

      before { object.tags = ["ruby", "custom_tag", "js"] }

      it "renders correct labels for matching choices and value-as-label for others" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="..." list="...">
            <tag-option value="ruby">Ruby Language</tag-option>
            <tag-option value="custom_tag">custom_tag</tag-option>
            <tag-option value="js">JavaScript Language</tag-option>
          </input-tag>
          <datalist id="...">
            <option value="ruby">Ruby Language</option>
            <option value="python">Python Language</option>
            <option value="js">JavaScript Language</option>
          </datalist>
        HTML
      end
    end

    context "with special characters in values and labels" do
      let(:choices) { [["C++ Programming", "cpp"], ["Node.js Framework", "nodejs"], ["C# Language", "csharp"]] }

      before { object.tags = ["cpp", "nodejs"] }

      it "properly escapes special characters in both values and labels" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="..." list="...">
            <tag-option value="cpp">C++ Programming</tag-option>
            <tag-option value="nodejs">Node.js Framework</tag-option>
          </input-tag>
          <datalist id="...">
            <option value="cpp">C++ Programming</option>
            <option value="nodejs">Node.js Framework</option>
            <option value="csharp">C# Language</option>
          </datalist>
        HTML
      end
    end

    context "with HTML-unsafe content" do
      let(:choices) { [["<Script>Tag</Script>", "script"], ["Safe & Sound", "safe"]] }

      before { object.tags = ["script", "<user_tag>"] }

      it "properly escapes HTML in both values and labels" do
        expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
          <input-tag name="test_model[tags]" id="..." list="...">
            <tag-option value="script">&lt;Script&gt;Tag&lt;/Script&gt;</tag-option>
            <tag-option value="&lt;user_tag&gt;">&lt;user_tag&gt;</tag-option>
          </input-tag>
          <datalist id="...">
            <option value="script">&lt;Script&gt;Tag&lt;/Script&gt;</option>
            <option value="safe">Safe &amp; Sound</option>
          </datalist>
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
          <input-tag name="test_model[tags]" id="..." list="...">
            <tag-option value="ruby">ruby</tag-option>
            <tag-option value="python">python</tag-option>
          </input-tag>
          <datalist id="...">
            <option value="ruby">ruby</option>
            <option value="python">python</option>
            <option value="javascript">javascript</option>
          </datalist>
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
        result = form_builder.bard_tag_field(:tags, choices)

        # Should show labels to user
        expect(result).to include("Ruby Programming Language")
        expect(result).to include("JavaScript")

        # But form field should store/submit the values
        expect(result).to include('name="test_model[tags]"')
        expect(result).to include('value="ruby"')
        expect(result).to include('value="js"')

        # Should NOT contain labels as values
        expect(result).not_to include('value="Ruby Programming Language"')
        expect(result).not_to include('value="JavaScript"')
      end
    end
  end

  describe "choice lookup functionality" do
    let(:choices) { [["Display A", "val_a"], ["Display B", "val_b"], ["Display C", "val_c"]] }

    it "correctly maps values to display labels" do
      # Test each permutation
      object.tags = ["val_a"]
      result1 = form_builder.bard_tag_field(:tags, choices)
      expect(result1).to include('value="val_a">Display A')

      object.tags = ["val_b", "val_c"]
      result2 = form_builder.bard_tag_field(:tags, choices)
      expect(result2).to include('value="val_b">Display B')
      expect(result2).to include('value="val_c">Display C')

      object.tags = ["val_a", "unknown_value", "val_c"]
      result3 = form_builder.bard_tag_field(:tags, choices)
      expect(result3).to include('value="val_a">Display A')
      expect(result3).to include('value="unknown_value">unknown_value')
      expect(result3).to include('value="val_c">Display C')
    end
  end

  describe "empty and edge cases with value/label separation" do
    let(:choices) { [["Label", "value"]] }

    it "handles empty tags array" do
      object.tags = []
      expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
        <input-tag name="test_model[tags]" id="..." list="..."></input-tag>
        <datalist id="...">
          <option value="value">Label</option>
        </datalist>
      HTML
    end

    it "handles nil tags" do
      object.tags = nil
      expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
        <input-tag name="test_model[tags]" id="..." list="..."></input-tag>
        <datalist id="...">
          <option value="value">Label</option>
        </datalist>
      HTML
    end

    it "handles empty string tags" do
      object.tags = [""]
      expect(form_builder.bard_tag_field(:tags, choices)).to match_html(<<~HTML)
        <input-tag name="test_model[tags]" id="..." list="...">
          <tag-option value=""></tag-option>
        </input-tag>
        <datalist id="...">
          <option value="value">Label</option>
        </datalist>
      HTML
    end
  end
end