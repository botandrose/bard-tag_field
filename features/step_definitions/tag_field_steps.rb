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

Then "the submitted course_ids should be {string}" do |expected_ids|
  submitted = JSON.parse(find("#submitted-params").text)
  actual_ids = submitted.dig("courses_item", "course_ids")
  expected = expected_ids.empty? ? [] : expected_ids.split(", ")
  expect(actual_ids).to eq(expected)
end

Then "the submitted tags should be {string}" do |expected_tags|
  submitted = JSON.parse(find("#submitted-params").text)
  actual_tags = submitted.dig("item", "tags") || []
  expected = expected_tags.empty? ? [] : expected_tags.split(", ")
  expect(actual_tags).to eq(expected)
end
