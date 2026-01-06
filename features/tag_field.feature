Feature: Tag field basic functionality

  Scenario: Rendering an empty tag field
    Given I am on the new item page
    Then I should see an empty "Tags" tag field

  Scenario: Rendering a tag field with existing tags
    Given I am on the new item page with tags "ruby, rails"
    Then I should see the following "Tags" tag field:
      | ruby | rails |

  Scenario: Submitting a tag field with existing tags
    Given I am on the new item page with tags "ruby, rails"
    When I press "Save"
    Then the submitted params should be:
      """json
      { "item": { "tags": ["ruby", "rails"] } }
      """
    And the model attributes should be:
      """json
      { "tags": ["ruby", "rails"] }
      """

  Scenario: Submitting an empty tag field
    Given I am on the new item page
    When I press "Save"
    Then the submitted params should be:
      """json
      { "item": { "tags": [""] } }
      """
    And the model attributes should be:
      """json
      { "tags": [] }
      """

  Scenario: Tag field with datalist shows available options
    Given I am on the new courses item page
    Then I should see the following "Courses" available tag options:
      | English Basics |
      | Algebra I      |
      | World History  |

  Scenario: Submitting a tag field with datalist preserves values
    Given I am on the new courses item page with courses "1, 2"
    When I press "Save"
    Then the submitted params should be:
      """json
      { "courses_item": { "course_ids": ["1", "2"] } }
      """
    And the model attributes should be:
      """json
      { "course_ids": ["1", "2"] }
      """
