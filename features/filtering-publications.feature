Feature: Filtering published publications

@javascript
Scenario: The list should update without a full page refresh
  Given a published publication "Lamb chops on baker's faces" for the organisation "Big co."
  And a published publication "Standard Beard Lengths" for the organisation "Acme"
  When I visit the list of publications
  And I filter publications to only those from the "Acme" department
  Then I should see the publication "Standard Beard Lengths"
  And I should not see the publication "Lamb chops on baker's faces"