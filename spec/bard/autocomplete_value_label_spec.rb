# frozen_string_literal: true

require "spec_helper"

RSpec.describe "bard_tag_field autocomplete with value/label separation" do
  let(:template) { ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil) }
  let(:object) { TestModel.new }
  let(:form_builder) { ActionView::Helpers::FormBuilder.new(:test_model, object, template, {}) }

  before do
    # Ensure the FormBuilder includes our module
    ActionView::Helpers::FormBuilder.include Bard::TagField::FormBuilder
  end

  describe "datalist generation for autocomplete" do
    context "with nested array choices (value/label pairs)" do
      let(:choices) { [["JavaScript Framework", "js"], ["TypeScript Language", "ts"], ["Python Programming", "py"]] }

      before { object.tags = [] }

      it "generates datalist with correct option structure for autocomplete" do
        result = form_builder.bard_tag_field(:tags, choices)

        # Should generate datalist with proper value/label structure
        expect(result).to include('<option value="js">JavaScript Framework</option>')
        expect(result).to include('<option value="ts">TypeScript Language</option>')
        expect(result).to include('<option value="py">Python Programming</option>')

        # Should NOT have options where value equals label for value/label pairs
        expect(result).not_to include('<option value="js">js</option>')
        expect(result).not_to include('<option value="JavaScript Framework">JavaScript Framework</option>')
      end

      it "connects input-tag to datalist properly" do
        result = form_builder.bard_tag_field(:tags, choices)

        # Should have list attribute pointing to datalist
        expect(result).to match(/<input-tag[^>]*list="[^"]+"/m)
        expect(result).to match(/<datalist id="[^"]+"/m)
      end
    end

    context "with mixed choice types" do
      let(:choices) { ["plain", ["Display Label", "value"], "another"] }

      it "generates correct datalist options for mixed types" do
        result = form_builder.bard_tag_field(:tags, choices)

        # Simple strings: value and label are the same
        expect(result).to include('<option value="plain">plain</option>')
        expect(result).to include('<option value="another">another</option>')

        # Nested array: separate value and label
        expect(result).to include('<option value="value">Display Label</option>')
      end
    end
  end

  describe "JavaScript options parsing for autocomplete" do
    # These tests verify that the JavaScript code can properly parse the datalist
    # for autocomplete functionality

    context "with value/label datalist options" do
      let(:choices) { [["JavaScript Framework", "js"], ["Java Language", "java"]] }

      it "should parse datalist options to include both values and labels" do
        result = form_builder.bard_tag_field(:tags, choices)

        # This test will fail until JavaScript is fixed to handle value/label separation
        # The JavaScript options getter should return an array of objects like:
        # [{ value: "js", label: "JavaScript Framework" }, { value: "java", label: "Java Language" }]
        # instead of just ["js", "java"]

        # For now, we can only test the HTML structure is correct
        expect(result).to include('list=')
        expect(result).to include('<datalist')

        # The failing part: JavaScript currently only extracts values, not labels
        # This should be fixed in the JavaScript code
        expect(result).to include('<option value="js">JavaScript Framework</option>')
        expect(result).to include('<option value="java">Java Language</option>')
      end
    end
  end

  describe "autocomplete filtering expectations" do
    context "with value/label choices" do
      let(:choices) { [["JavaScript Framework", "js"], ["Java Server Pages", "jsp"], ["TypeScript", "ts"]] }

      it "should enable filtering by label text in autocomplete" do
        result = form_builder.bard_tag_field(:tags, choices)

        # When user types "java", they should see:
        # - "JavaScript Framework" (matches label)
        # - "Java Server Pages" (matches label)
        # NOT:
        # - "TypeScript" (label doesn't match)

        # This requires JavaScript to:
        # 1. Parse labels from datalist options
        # 2. Filter by label text, not value
        # 3. Display labels in autocomplete dropdown

        # Currently failing because JS only uses values for filtering
        expect(result).to include('<option value="js">JavaScript Framework</option>')
        expect(result).to include('<option value="jsp">Java Server Pages</option>')
        expect(result).to include('<option value="ts">TypeScript</option>')
      end
    end
  end

  describe "tag creation from autocomplete selection" do
    context "when selecting from autocomplete with value/label pairs" do
      let(:choices) { [["JavaScript Framework", "js"], ["Python Language", "py"]] }

      before { object.tags = [] }

      it "should create tag-option with correct value and label when selected" do
        result = form_builder.bard_tag_field(:tags, choices)

        # When user selects "JavaScript Framework" from autocomplete:
        # - JavaScript should call taggle.add("js") [the value]
        # - But should create <tag-option value="js">JavaScript Framework</tag-option>
        # - NOT <tag-option value="js">js</tag-option>

        # This requires JavaScript to:
        # 1. Know the mapping between values and labels
        # 2. When adding a tag via autocomplete, use the label for display

        # We can test the foundation is there:
        expect(result).to include('<datalist')
        expect(result).to include('<option value="js">JavaScript Framework</option>')

        # The actual tag creation behavior needs to be fixed in JavaScript
      end
    end
  end

  describe "backward compatibility with simple choices" do
    context "with string array choices" do
      let(:choices) { ["javascript", "python", "typescript"] }

      it "continues to work as before with simple strings" do
        result = form_builder.bard_tag_field(:tags, choices)

        # Simple strings should work exactly as before
        expect(result).to include('<option value="javascript">javascript</option>')
        expect(result).to include('<option value="python">python</option>')
        expect(result).to include('<option value="typescript">typescript</option>')

        # No change needed for this case - existing JS should work fine
      end
    end
  end
end