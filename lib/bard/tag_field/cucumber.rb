class Chop::Form::TagField < Chop::Form::Field
  def self.css_selector
    "input-tag"
  end

  def matches?
    field.tag_name == "input-tag"
  end

  def get_value
    field.all("tag-option").map(&:text)
  end

  def diff_value
    get_value.join(", ")
  end

  def set_value
    if field[:multiple]
      value.to_s.split(", ").map(&:strip)
    else
      value.to_s.strip
    end
  end

  def fill_in!
    session.execute_script("document.getElementById('#{field[:id]}').value = #{set_value.to_json}")
  end
end

When "I fill in the {string} tag field with {string}" do |field, value|
  find_input_tag_field(field).click
  page.driver.browser.keyboard.type(value)
end

When "I remove {string} from the {string} tag field" do |value, field|
  within find_input_tag_field(field) do
    within find("tag-option", text: value).shadow_root do
      find("button").trigger("click")
    end
  end
end

Then "I should see the following {string} tag field:" do |field, table|
  tags = input_tag_value(find_input_tag_field(field))
  table.diff! [tags]
end

Then "I should see an empty {string} tag field" do |field|
  expect(find_input_tag_field(field)).to have_no_css("tag-option")
end

Then "I should see the following {string} available tag options:" do |field, table|
  field = find_input_tag_field(field)
  options = field.all("datalist option", visible: false).map { |e| e[:innerText] }
  expect(options).to eq(table.raw.flatten)
end

Then "I should see the following {string} tag field autocomplete options:" do |field, table|
  within find_input_tag_field(field).shadow_root do
    expect(all("li").map(&:text)).to eq(table.raw.flatten)
  end
end

def find_input_tag_field(label)
  find("##{find("label", text: label)[:for]}")
end

def input_tag_value(field)
  field.all("tag-option").map(&:text)
end

def input_tag_field actual, root, label: "Labels"
  index = actual.index { |row| row.first == "Description" }
  tags = input_tag_value(find_input_tag_field(label))
  actual.insert index, [label, tags.join(", ")]
end
