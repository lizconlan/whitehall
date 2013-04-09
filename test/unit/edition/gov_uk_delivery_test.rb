require "test_helper"

class Edition::GovUkDeliveryTest < ActiveSupport::TestCase
  test "#govuk_delivery_tags returns a feed for 'all' by default" do
    assert_equal ["https://#{Whitehall.public_host}/government/feed"], build(:policy).govuk_delivery_tags
  end

  test '#govuk_delivery_tags returns an atom feed url for the organisation and a topic' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:policy, topics: [topic], organisations: [organisation])

    assert edition.govuk_delivery_tags.include? "https://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic.slug}"

  end

  test '#govuk_delivery_tags returns an atom feed url for each topic/organisation combination' do
    topic1 = create(:topic)
    topic2 = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:policy, topics: [topic1, topic2], organisations: [organisation])

    assert edition.govuk_delivery_tags.include? "https://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic1.slug}"
    assert edition.govuk_delivery_tags.include? "https://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic2.slug}"
  end

  test '#govuk_delivery_tags returns an atom feed url that does not include departments as well as a regular URL' do
    topic1 = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:policy, topics: [topic1], organisations: [organisation])

    assert edition.govuk_delivery_tags.include? "https://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&topics%5B%5D=#{topic1.slug}"
    assert edition.govuk_delivery_tags.include? "https://#{Whitehall.public_host}/government/policies.atom?topics%5B%5D=#{topic1.slug}"
  end

  test '#govuk_delivery_tags includes relevant to local param if edition is relevant' do
    topic = create(:topic)
    organisation = create(:ministerial_department)
    edition = create(:policy, topics: [topic], organisations: [organisation], relevant_to_local_government: true)

    assert edition.govuk_delivery_tags.include? "https://#{Whitehall.public_host}/government/policies.atom?departments%5B%5D=#{organisation.slug}&relevant_to_local_government=1&topics%5B%5D=#{topic.slug}"
  end

  test '#notify_govuk_delivery queues a GovUkNotificationJob' do
    assert_difference 'Delayed::Job.count', 1 do
      policy = create(:policy)
      policy.notify_govuk_delivery
    end
  end

  test "notifies gov uk delivery after publishing a policy" do
    policy = create(:policy)
    policy.first_published_at = Time.zone.now
    policy.major_change_published_at = Time.zone.now

    policy.expects(:notify_govuk_delivery).once
    policy.publish!
  end

  test "notifies gov uk delivery after publishing a news article" do
    news_article = create(:news_article)
    news_article.first_published_at = Time.zone.now
    news_article.major_change_published_at = Time.zone.now

    news_article.expects(:notify_govuk_delivery).once
    news_article.publish!
  end

  test "notifies gov uk delivery after publishing a publication" do
    publication = create(:publication)
    publication.first_published_at = Time.zone.now
    publication.major_change_published_at = Time.zone.now

    publication.expects(:notify_govuk_delivery).once
    publication.publish!
  end

  test 'does not notify gov uk delivery if the change was minor' do
    policy = create(:policy, minor_change: true)
    policy.first_published_at = Time.zone.now
    policy.major_change_published_at = Time.zone.now

    policy.expects(:notify_govuk_delivery).never
    policy.publish!
  end
end
