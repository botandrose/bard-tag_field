Given "I am on the new item page" do
  visit "/items/new"
end

Given "I am on the new item page with tags {string}" do |tags|
  visit "/items/new?tags[]=#{tags.split(", ").join("&tags[]=")}"
end

Given "I am on the new courses item page" do
  visit "/courses_items/new"
end

Given "I am on the new courses item page with courses {string}" do |courses|
  visit "/courses_items/new?course_ids[]=#{courses.split(", ").join("&course_ids[]=")}"
end

When "I fill in the following:" do |table|
  table.fill_in!
end

When "I press {string}" do |button|
  click_button button
end

Then "the submitted params should be:" do |json|
  submitted = JSON.parse(find("#submitted-params").text)
  expect(submitted).to include(JSON.parse(json))
end

Then "the model attributes should be:" do |json|
  model_attrs = JSON.parse(find("#model-attributes").text)
  expect(model_attrs).to eq(JSON.parse(json))
end
