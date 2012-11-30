When /^I create a new field of operation called "([^"]*)" with description "([^"]*)"$/ do |field_name, description|
  visit admin_operational_fields_path
  click_on "Add field of operation"
  fill_in "Name", with: field_name
  fill_in "Description", with: description
  click_on "Save"
end

Then /^I am able to associate fatality notices with "([^"]*)"$/ do |field_name|
  begin_drafting_document type: "fatality_notice", title: "fatality notice"
  select field_name, from: "Field of operation"
end