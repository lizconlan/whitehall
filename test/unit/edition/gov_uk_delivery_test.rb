# encoding: utf-8

require "test_helper"

class Edition::GovUkDeliveryTest < ActiveSupport::TestCase

  test "#govuk_delivery_tags for a policy returns a feed for 'all'" do
    assert build(:policy).govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/feed"
  end

  test '#govuk_delivery_tags for a relevant to local government policy does not put the relevant to local param on the "all" feed url' do
    edition = build(:policy, relevant_to_local_government: true)

    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/feed?relevant_to_local_government=1"
  end

  ### begin document type specific tests

  ### policy feed urls tests

  test '#govuk_delivery_tags for a policy returns an atom feed url for the organisation and a topic' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:policy, topics: [topic], organisations: [organisation])

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic.slug}"
  end

  test '#govuk_delivery_tags for a policy returns an atom feed url for each topic/organisation combination' do
    topic1 = create(:topic)
    topic2 = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:policy, topics: [topic1, topic2], organisations: [organisation])

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic1.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic2.slug}"
  end

  test '#govuk_delivery_tags for a policy returns an atom feed url that does not include topics' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:policy, topics: [topic], organisations: [organisation])

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}"
  end

  test '#govuk_delivery_tags for a policy returns an atom feed url that does not include departments' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:policy, topics: [topic], organisations: [organisation])

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?topics%5B%5D=#{topic.slug}"
  end

  test '#govuk_delivery_tags for a policy returns an atom feed url that does not include departments or topics' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:policy, topics: [topic], organisations: [organisation])

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom"
  end

  test '#govuk_delivery_tags for a relevant to local government policy puts the relevant to local param on all policies.atom urls' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:policy, topics: [topic], organisations: [organisation], relevant_to_local_government: true)

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&relevant_to_local_government=1"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?relevant_to_local_government=1"

    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom?topics%5B%5D=#{topic.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/policies.atom"
  end

  ### publications feed urls tests

  test '#govuk_delivery_tags for a publication returns an atom feed url for the organisation and a topic (with and without the publication_filter_option param)' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:publication, organisations: [organisation], publication_type: PublicationType::CorporateReport)
    edition.stubs(:topics).returns [topic]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&publication_filter_option=corporate-reports&topics%5B%5D=#{topic.slug}"
  end

  test '#govuk_delivery_tags for a publication returns an atom feed url for each topic/organisation combination' do
    topic1 = create(:topic)
    topic2 = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:publication, organisations: [organisation], publication_type: PublicationType::CorporateReport)
    edition.stubs(:topics).returns [topic1, topic2]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic1.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic2.slug}"

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&publication_filter_option=corporate-reports&topics%5B%5D=#{topic1.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&publication_filter_option=corporate-reports&topics%5B%5D=#{topic2.slug}"
  end

  test '#govuk_delivery_tags for a publication returns an atom feed url that does not include topics (with and without the publication_filter_option param)' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:publication, organisations: [organisation], publication_type: PublicationType::CorporateReport)
    edition.stubs(:topics).returns [topic]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&publication_filter_option=corporate-reports"
  end

  test '#govuk_delivery_tags for a publication returns an atom feed url that does not include departments (with and without the publication_filter_option param)' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:publication, organisations: [organisation], publication_type: PublicationType::CorporateReport)
    edition.stubs(:topics).returns [topic]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?publication_filter_option=corporate-reports&topics%5B%5D=#{topic.slug}"
  end

  test '#govuk_delivery_tags for a publication returns an atom feed url that does not include departments or topics (with and without the publication_filter_option param)' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:publication, organisations: [organisation], publication_type: PublicationType::CorporateReport)
    edition.stubs(:topics).returns [topic]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?publication_filter_option=corporate-reports"
  end

  test '#govuk_delivery_tags for a relevant to local government publication puts the relevant to local param on all publications.atom urls' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:publication, organisations: [organisation], relevant_to_local_government: true, publication_type: PublicationType::CorporateReport)
    edition.stubs(:topics).returns [topic]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&relevant_to_local_government=1"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?relevant_to_local_government=1"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&publication_filter_option=corporate-reports&relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&publication_filter_option=corporate-reports&relevant_to_local_government=1"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?publication_filter_option=corporate-reports&relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?publication_filter_option=corporate-reports&relevant_to_local_government=1"

    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?topics%5B%5D=#{topic.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&publication_filter_option=corporate-reports&topics%5B%5D=#{topic.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?departments%5B%5D=#{organisation.slug}&publication_filter_option=corporate-reports"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?publication_filter_option=corporate-reports&topics%5B%5D=#{topic.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/publications.atom?publication_filter_option=corporate-reports"
  end

  ## announcements feed urls tests

  test '#govuk_delivery_tags for an announcement returns an atom feed url for the organisation and a topic (with and without the publication_filter_option param)' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:news_article, organisations: [organisation], news_article_type: NewsArticleType::PressRelease)
    edition.stubs(:topics).returns [topic]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic.slug}"
  end

  test '#govuk_delivery_tags for an announcement returns an atom feed url for each topic/organisation combination' do
    topic1 = create(:topic)
    topic2 = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:news_article, organisations: [organisation], news_article_type: NewsArticleType::PressRelease)
    edition.stubs(:topics).returns [topic1, topic2]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic1.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic2.slug}"

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic1.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic2.slug}"
  end

  test '#govuk_delivery_tags for an announcement returns an atom feed url that does not include topics (with and without the publication_filter_option param)' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:news_article, organisations: [organisation], news_article_type: NewsArticleType::PressRelease)
    edition.stubs(:topics).returns [topic]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?departments%5B%5D=#{organisation.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&departments%5B%5D=#{organisation.slug}"
  end

  test '#govuk_delivery_tags for an announcement returns an atom feed url that does not include departments (with and without the publication_filter_option param)' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:news_article, organisations: [organisation], news_article_type: NewsArticleType::PressRelease)
    edition.stubs(:topics).returns [topic]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&topics%5B%5D=#{topic.slug}"
  end

  test '#govuk_delivery_tags for an announcement returns an atom feed url that does not include departments or topics (with and without the publication_filter_option param)' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:news_article, organisations: [organisation], news_article_type: NewsArticleType::PressRelease)
    edition.stubs(:topics).returns [topic]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases"
  end

  test '#govuk_delivery_tags for a relevant to local government announcement puts the relevant to local param on all publications.atom urls' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:news_article, organisations: [organisation], relevant_to_local_government: true, news_article_type: NewsArticleType::PressRelease)
    edition.stubs(:topics).returns [topic]

    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?departments%5B%5D=#{organisation.slug}&relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?departments%5B%5D=#{organisation.slug}&relevant_to_local_government=1"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?relevant_to_local_government=1"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&departments%5B%5D=#{organisation.slug}&relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&departments%5B%5D=#{organisation.slug}&relevant_to_local_government=1"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
    assert edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&relevant_to_local_government=1"

    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?departments%5B%5D=#{organisation.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?topics%5B%5D=#{topic.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&departments%5B%5D=#{organisation.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases&topics%5B%5D=#{topic.slug}"
    refute edition.govuk_delivery_tags.include? "#{Whitehall.public_protocol}://#{Whitehall.public_host}/government/announcements.atom?announcement_filter_option=press-releases"
  end

  ## end document type specific tests

  test '#govuk_delivery_email_body generates a utf-8 encoded body' do
    publication = create(:news_article, title: "Café".encode("UTF-8"))

    body = publication.govuk_delivery_email_body
    assert_includes body, publication.title
    assert_equal 'UTF-8', body.encoding.name
  end

  test '#notify_govuk_delivery sends a notification via the govuk delivery client when there are topics' do
    policy = create(:policy, topics: [create(:topic)])
    policy.stubs(:govuk_delivery_email_body).returns('email body')
    Whitehall.govuk_delivery_client.expects(:notify).with(policy.govuk_delivery_tags, policy.title, 'email body')

    policy.notify_govuk_delivery
  end

  test '#notify_govuk_delivery does nothing if the change is minor' do
    policy = create(:policy, topics: [create(:topic)], minor_change: true)
    Whitehall.govuk_delivery_client.expects(:notify).never

    policy.notify_govuk_delivery
  end

  test '#notify_govuk_delivery swallows errors from the API' do
    policy = create(:policy, topics: [create(:topic)])
    Whitehall.govuk_delivery_client.expects(:notify).raises(GdsApi::HTTPErrorResponse, 500)

    assert_nothing_raised { policy.notify_govuk_delivery }
  end

  test '#notify_govuk_delivery swallows timeout errors from the API' do
    policy = create(:policy, topics: [create(:topic)])
    Whitehall.govuk_delivery_client.expects(:notify).raises(GdsApi::TimedOutException)

    assert_nothing_raised { policy.notify_govuk_delivery }
  end

  test "should notify govuk_delivery on publishing policies" do
    Edition::AuditTrail.whodunnit = create(:user)
    policy = create(:policy, topics: [create(:topic), create(:topic)])
    policy.first_published_at = Time.zone.now
    policy.major_change_published_at = Time.zone.now

    policy.expects(:notify_govuk_delivery).once
    policy.publish!
  end

  test "should notify govuk_delivery on publishing news articles" do
    news_article = create(:news_article)
    news_article.first_published_at = Time.zone.now
    news_article.major_change_published_at = Time.zone.now

    news_article.expects(:notify_govuk_delivery).once
    news_article.publish!
  end

  test "should notify govuk_delivery on publishing publications" do
    publication = create(:publication)
    publication.first_published_at = Time.zone.now
    publication.major_change_published_at = Time.zone.now

    publication.expects(:notify_govuk_delivery).once
    publication.publish!
  end

  test "should link to full URL in email" do
    publication = create(:publication)
    publication.first_published_at = Time.zone.now
    publication.major_change_published_at = Time.zone.now

    assert_match /#{Whitehall.public_host}/, publication.govuk_delivery_email_body
  end
end
