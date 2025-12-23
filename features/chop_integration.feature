Feature: Chop form integration

  Scenario: Filling in tag field with display labels resolves to submit values
    Given I am on the new courses item page
    When I fill in the following:
      | Courses | English Basics, Algebra I |
    And I press "Save"
    Then the submitted course_ids should be "1, 2"

  Scenario: Filling in tag field with a single value
    Given I am on the new courses item page
    When I fill in the following:
      | Courses | World History |
    And I press "Save"
    Then the submitted course_ids should be "3"

  Scenario: Filling in tag field with unknown values passes them through
    Given I am on the new courses item page
    When I fill in the following:
      | Courses | English Basics, Custom Course |
    And I press "Save"
    Then the submitted course_ids should be "1, Custom Course"

  Scenario: Filling in simple tag field without datalist
    Given I am on the new item page
    When I fill in the following:
      | Tags | ruby, rails, javascript |
    And I press "Save"
    Then the submitted tags should be "ruby, rails, javascript"

  Scenario: Clearing a tag field by setting empty value
    Given I am on the new item page
    When I fill in the following:
      | Tags | |
    And I press "Save"
    Then the submitted tags should be ""

  Scenario: Overwriting existing tags with new values
    Given I am on the new item page with tags "old, tags"
    When I fill in the following:
      | Tags | new, values |
    And I press "Save"
    Then the submitted tags should be "new, values"

  Scenario: Overwriting existing courses with new values via display labels
    Given I am on the new courses item page with courses "1"
    When I fill in the following:
      | Courses | Algebra I, World History |
    And I press "Save"
    Then the submitted course_ids should be "2, 3"

  Scenario: Filling in all available courses
    Given I am on the new courses item page
    When I fill in the following:
      | Courses | English Basics, Algebra I, World History |
    And I press "Save"
    Then the submitted course_ids should be "1, 2, 3"
