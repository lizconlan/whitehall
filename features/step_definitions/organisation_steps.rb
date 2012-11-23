Given /^the organisation "([^"]*)" contains some policies$/ do |name|
  editions = Array.new(5) { build(:published_policy) } + Array.new(2) { build(:draft_policy) }
  create(:ministerial_department, name: name, editions: editions)
end

Given /^other organisations also have policies$/ do
  create(:organisation, editions: [build(:published_policy)])
  create(:organisation, editions: [build(:published_policy)])
end

Given /^the organisation "([^"]*)" exists$/ do |name|
  create(:ministerial_department, name: name)
end

Given /^two organisations "([^"]*)" and "([^"]*)" exist$/ do |first_organisation, second_organisation|
  create(:organisation, name: first_organisation)
  create(:organisation, name: second_organisation)
end

Given /^the "([^"]*)" organisation is associated with several ministers and civil servants$/ do |organisation_name|
  organisation = Organisation.find_by_name(organisation_name) || create(:ministerial_department, name: organisation_name)
  3.times do |x|
    person = create(:person)
    ministerial_role = create(:ministerial_role, cabinet_member: (x == 1))
    organisation.ministerial_roles << ministerial_role
    create(:role_appointment, role: ministerial_role, person: person)
  end
  3.times do |x|
    person = create(:person)
    role = create(:board_member_role, permanent_secretary: (x == 1))
    organisation.roles << role
    create(:role_appointment, role: role, person: person)
  end
end

Given /^the "([^"]*)" organisation is associated with traffic commissioners$/ do |organisation_name|
  organisation = Organisation.find_by_name(organisation_name) || create(:ministerial_department, name: organisation_name)
  traffic_commissioner_role = create(:traffic_commissioner_role, name: "traffic-commissioner-role", organisations: [organisation])
end

Given /^a submitted corporate publication "([^"]*)" about the "([^"]*)"$/ do |publication_title, organisation_name|
  organisation = Organisation.find_by_name(organisation_name)
  create(:submitted_corporate_publication, title: publication_title, organisations: [organisation])
end

Given /^the organisation "([^"]*)" is associated with consultations "([^"]*)" and "([^"]*)"$/ do |name, consultation_1, consultation_2|
  organisation = create(:organisation, name: name)
  create(:published_consultation, title: consultation_1, organisations: [organisation])
  create(:published_consultation, title: consultation_2, organisations: [organisation])
end

Given /^a published publication "([^"]*)" with a PDF attachment and alternative format provider "([^"]*)"$/ do |title, organisation_name|
  organisation = Organisation.find_by_name!(organisation_name)
  publication = create(:published_publication, :with_attachment, title: title, body: "!@1", organisations: [organisation], alternative_format_provider: organisation)
  @attachment_title = publication.attachments.first.title
  @attachment_filename = publication.attachments.first.filename
end

Given /^I set the alternative format contact email of "([^"]*)" to "([^"]*)"$/ do |organisation_name, email|
  organisation = Organisation.find_by_name!(organisation_name)
  visit edit_admin_organisation_path(organisation)
  fill_in "organisation_alternative_format_contact_email", with: email
  click_button "Save"
end

When /^I visit the "([^"]*)" organisation$/ do |name|
  visit_organisation name
end

When /^I feature the news article "([^"]*)" for "([^"]*)"$/ do |news_article_title, organisation_name|
  When %%I feature the news article "#{news_article_title}" for "#{organisation_name}" with image "minister-of-funk.960x640.jpg"%
end

When /^I feature the news article "([^"]*)" for "([^"]*)" with image "([^"]*)"$/ do |news_article_title, organisation_name, image_filename|
  organisation = Organisation.find_by_name!(organisation_name)
  visit admin_organisation_path(organisation)
  news_article = NewsArticle.find_by_title(news_article_title)
  within record_css_selector(news_article) do
    click_link "Feature"
  end
  attach_file "Select an image to be shown when featuring", Rails.root.join("test/fixtures/#{image_filename}")
  fill_in :alt_text, with: "An accessible description of the image"
  click_button "Save"
end

When /^I order the featured items in the "([^"]*)" organisation as:$/ do |name, table|
  organisation = Organisation.find_by_name!(name)
  visit admin_organisation_path(organisation)
  table.rows.each_with_index do |(title), index|
    fill_in title, with: index
  end
  click_button "Save"
end

When /^I delete the organisation "([^"]*)"$/ do |name|
  organisation = Organisation.find_by_name!(name)
  visit edit_admin_organisation_path(organisation)
  click_button "delete"
end

Then /^there should not be an organisation called "([^"]*)"$/ do |name|
  refute Organisation.find_by_name(name)
end

Then /^I should be able to view all civil servants for the "([^"]*)" organisation$/ do |name|
  organisation = Organisation.find_by_name!(name)
  organisation.board_member_roles.each do |role|
    assert page.has_css?(record_css_selector(role))
  end
end

Then /^I should be able to view all ministers for the "([^"]*)" organisation$/ do |name|
  organisation = Organisation.find_by_name!(name)
  organisation.ministerial_roles.each do |role|
    assert page.has_css?(record_css_selector(role))
  end
end

Then /^I should be able to view all traffic commissioners for the "([^"]*)" organisation$/ do |name|
  organisation = Organisation.find_by_name!(name)
  organisation.traffic_commissioner_roles.each do |role|
    assert page.has_css?(record_css_selector(role))
  end
end

Then /^I should see the featured news articles in the "([^"]*)" organisation are:$/ do |name, expected_table|
  visit_organisation name
  rows = find(featured_documents_selector).all('.news_article')
  table = rows.collect do |row|
    [
      row.find('h2').text.strip,
      File.basename(row.find('.featured-image')['src'])
    ]
  end
  expected_table.diff!(table)
end

Then /^I should only see published policies belonging to the "([^"]*)" organisation$/ do |name|
  organisation = Organisation.find_by_name!(name)
  editions = records_from_elements(Edition, page.all(".document"))
  assert editions.all? { |edition| organisation.editions.published.include?(edition) }
end

Then /^I should see the "([^"]*)" organisation's (.*) page$/ do |organisation_name, page_name|
  title =
    case page_name
    when 'about'    then "About"
    when 'news'     then "News"
    when 'home'     then organisation_name
    when 'policies' then  "Policies"
    end

  assert page.has_css?('title', text: title)
end

def navigate_to_organisation(page_name)
  within('nav.sub_navigation') do
    click_link page_name
  end
end

Then /^I should see a mailto link for the alternative format contact email "([^"]*)"$/ do |email|
  assert page.has_css?("a[href^=\"mailto:#{email}\"]")
end

Then /^I cannot see links to FOI releases or Transparency data on the "([^"]*)" about page$/ do |name|
  visit_organisation_about_page name
  refute page.has_css?('a', text: 'FOI releases')
  refute page.has_css?('a', text: 'Transparency data')
end

When /^I associate an FOI release to the "([^"]*)"$/ do |name|
  organisation = Organisation.find_by_name!(name)
  publication = create(:published_publication, :foi_release, organisations: [organisation])
end

Then /^I can see a link to "([^"]*)" on the "([^"]*)" about page$/ do |link_text, name|
  visit_organisation_about_page name
  assert page.has_css?('a', text: link_text)
end

When /^I associate a Transparency data publication to the "([^"]*)"$/ do |name|
  organisation = Organisation.find_by_name!(name)
  publication = create(:published_publication, :transparency_data, organisations: [organisation])
end

When /^I add some mainstream links to "([^"]*)" via the admin$/ do |organisation_name|
  organisation = Organisation.find_by_name!(organisation_name)
  visit admin_organisation_path(organisation)
  click_link "Edit"
  within ".organisation_mainstream_links" do
    fill_in "Url", with: "https://www.gov.uk/mainstream/tool-alpha"
    fill_in "Title", with: "Tool Alpha"
  end
  click_button "Save"
end

Then /^the mainstream links for "([^"]*)" should be visible on the public site$/ do |organisation_name|
  visit_organisation organisation_name
  within ".organisation_mainstream_links" do
    assert page.has_css?("a[href='https://www.gov.uk/mainstream/tool-alpha']", "Tool Alpha")
  end
end
