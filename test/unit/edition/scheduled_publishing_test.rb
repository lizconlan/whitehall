require "test_helper"

class Edition::ScheduledPublishingTest < ActiveSupport::TestCase
  test "draft, submitted or rejected edition is not valid if scheduled_publication date is in the past" do
    editor = build(:departmental_editor)
    Edition.state_machine.states.each do |state|
      edition = create(:edition, state.name, scheduled_publication: 1.minute.from_now)
      Timecop.freeze(2.minutes.from_now) do
        edition.stubs(:reason_to_prevent_approval_by).returns(nil)
        if [:draft, :submitted, :rejected].include?(state.name)
          refute edition.valid?, "#{state.name} edition should be invalid"
          assert edition.errors[:scheduled_publication].include?("date must be in the future")
        else
          assert edition.valid?, "#{state.name} edition should be valid, but #{edition.errors.full_messages.inspect}"
        end
      end
    end
  end

  test "scheduled_publication can be in the past when rejecting" do
    editor = create(:departmental_editor)
    edition = create(:edition, :submitted, scheduled_publication: 1.minute.from_now)
    Timecop.freeze(2.minutes.from_now) do
      assert edition.reject!
      assert edition.rejected?
      assert edition.reload.rejected?
    end
  end

  test "scheduled_publication must be in the future if editing a rejected document" do
    editor = create(:departmental_editor)
    edition = create(:edition, :rejected, scheduled_publication: 1.minute.from_now)
    Timecop.freeze(2.minutes.from_now) do
      refute edition.valid?
      edition.scheduled_publication = 1.minute.from_now
      assert edition.valid?
    end
  end

  test "is publishable if submitted without scheduled_publication date and there is no reason to prevent approval" do
    editor = build(:departmental_editor)
    edition = build(:submitted_edition, scheduled_publication: nil)
    edition.stubs(:reason_to_prevent_approval_by).returns(nil)
    assert edition.publishable_by?(editor)
  end

  test "is never publishable if submitted with a scheduled_publication date, even if no reason to prevent approval" do
    editor = build(:departmental_editor)
    edition = build(:submitted_edition, scheduled_publication: 1.day.from_now)
    edition.stubs(:reason_to_prevent_approval_by).returns(nil)
    refute edition.publishable_by?(editor)
    refute edition.publishable_by?(editor, force: true)
    assert_equal "Can't publish this edition immediately as it has a scheduled publication date. Schedule it for publication or remove the scheduled publication date.", edition.reason_to_prevent_publication_by(editor)
  end

  test "is never publishable if scheduled, but the scheduled_publication date has not yet arrived" do
    editor = build(:departmental_editor)
    edition = build(:scheduled_edition, scheduled_publication: 1.day.from_now)
    edition.stubs(:reason_to_prevent_approval_by).returns(nil)
    Timecop.freeze(edition.scheduled_publication - 1.second) do
      refute edition.publishable_by?(editor)
      refute edition.publishable_by?(editor, force: true)
      assert_equal "This edition is scheduled for publication on #{edition.scheduled_publication.to_s}, and may not be published before", edition.reason_to_prevent_publication_by(editor)
    end
  end

  test "is not schedulable if already scheduled" do
    editor = build(:departmental_editor)
    edition = build(:scheduled_edition, scheduled_publication: 1.day.from_now)
    assert_equal "This edition is already scheduled for publication", edition.reason_to_prevent_scheduling_by(editor)
    refute edition.schedulable_by?(editor)
    refute edition.schedulable_by?(editor, force: true)
  end

  test "is publishable by scheduled publishing robot if scheduled and the scheduled_publication date has passed" do
    editor = build(:scheduled_publishing_robot)
    edition = build(:scheduled_edition, scheduled_publication: 1.day.from_now)
    Timecop.freeze(edition.scheduled_publication) do
      assert_equal nil, edition.reason_to_prevent_publication_by(editor)
      assert edition.publishable_by?(editor)
    end
  end

  test "publishing a force-scheduled edition does not clear the force_published flag" do
    robot_user = create(:scheduled_publishing_robot)
    edition = create(:scheduled_edition, scheduled_publication: 1.day.from_now, force_published: true)
    Timecop.freeze(edition.scheduled_publication) do
      edition.publish_as(robot_user)
    end
    assert_equal true, edition.reload.force_published
  end

  test "publishing a scheduled edition purges cache for pages on which edition appears" do
    robot_user = create(:scheduled_publishing_robot)
    edition = create(:scheduled_edition, scheduled_publication: 1.day.from_now)
    edition.stubs(:urls_on_which_edition_appears).returns(["url-1", "url-2"])
    Whitehall.cache_buster.expects(:purge).with(["url-1", "url-2"])
    Timecop.freeze(edition.scheduled_publication) do
      edition.publish_as(robot_user)
    end
  end

  test "publishing a submitted edition does not purges cache for pages on which edition appears" do
    editor = create(:departmental_editor)
    edition = create(:submitted_edition)
    Whitehall.cache_buster.expects(:purge).never
    edition.publish_as(editor)
  end

  test "is not schedulable if there is a reason to prevent approval" do
    edition = build(:submitted_edition, scheduled_publication: 1.day.from_now)
    arbitrary_reason = "Because I said so"
    edition.stubs(:reason_to_prevent_approval_by).returns(arbitrary_reason)
    refute edition.schedulable_by?(stub)
    assert_equal arbitrary_reason, edition.reason_to_prevent_scheduling_by(stub)
  end

  test "is schedulable if no reason to prevent approval and submitted with a scheduled_publication date" do
    editor = build(:departmental_editor)
    edition = build(:submitted_edition, scheduled_publication: 1.day.from_now)
    edition.stubs(:reason_to_prevent_approval_by).returns(nil)
    assert edition.schedulable_by?(editor)
  end

  test "scheduling marks edition as scheduled" do
    edition = create(:submitted_edition, scheduled_publication: 1.day.from_now)
    edition.schedule_as(create(:departmental_editor))
    assert edition.reload.scheduled?
  end

  test "scheduling fails if not schedulable by user" do
    editor = create(:departmental_editor)
    edition = create(:submitted_edition)
    edition.stubs(:schedulable_by?).with(editor, anything).returns(false)
    refute edition.schedule_as(editor)
    refute edition.reload.published?
  end

  test "scheduling adds reason for failure to validation errors" do
    editor = create(:departmental_editor)
    edition = create(:submitted_edition)
    edition.stubs(:schedulable_by?).returns(false)
    edition.stubs(:reason_to_prevent_scheduling_by).with(editor, {}).returns('a spurious reason')
    edition.schedule_as(editor)
    assert_equal ['a spurious reason'], edition.errors.full_messages
  end

  test "is unschedulable only if scheduled" do
    author = build(:author)
    Edition.state_machine.states.each do |state|
      edition = build(:edition, state.name)
      if state.name == :scheduled
        assert edition.unschedulable_by?(author)
        assert_equal nil, edition.reason_to_prevent_unscheduling_by(author)
      else
        refute edition.unschedulable_by?(author)
        assert_equal "This edition is not scheduled for publication", edition.reason_to_prevent_unscheduling_by(author)
      end
    end
  end

  test "unscheduling changes state to submitted, clears force publish flag and returns true on success" do
    author = build(:author)
    edition = build(:edition, :scheduled, force_published: true)
    assert edition.unschedule_as(author)
    assert_equal "submitted", edition.state
    assert_equal false, edition.force_published
  end

  test "unscheduling adds reason for failure to validation errors" do
    author = build(:author)
    edition = build(:edition, :scheduled)
    edition.stubs(:unschedulable_by?).returns(false)
    edition.stubs(:reason_to_prevent_unscheduling_by).returns('a spurious reason')
    edition.unschedule_as(author)
    assert_equal ['a spurious reason'], edition.errors.full_messages
  end

  test "can find editions due for publication" do
    due_in_one_day = create(:edition, :scheduled, scheduled_publication: 1.day.from_now)
    due_in_two_days = create(:edition, :scheduled, scheduled_publication: 2.days.from_now)
    already_published = create(:edition, :published, scheduled_publication: 1.day.from_now)
    Timecop.freeze 1.day.from_now do
      assert_equal [due_in_one_day], Edition.due_for_publication
    end
    Timecop.freeze 2.days.from_now do
      assert_equal [due_in_one_day, due_in_two_days], Edition.due_for_publication
    end
  end

  test ".scheduled_publishing_robot creates a scheduled publishing robot user account if none exists" do
    assert_difference "User.count", 1 do
      Edition.scheduled_publishing_robot
    end
    assert_difference "User.count", 0 do
      Edition.scheduled_publishing_robot
    end
    assert_equal nil, Edition.scheduled_publishing_robot.uid
    assert Edition.scheduled_publishing_robot.can_publish_scheduled_editions?
  end
end

class Edition::PublishAllDueEditionsTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false

  setup do
    DatabaseCleaner.clean_with :truncation
  end

  teardown do
    DatabaseCleaner.clean_with :truncation
  end

  test "#publish_all_due_editions_as publishes all due publications using the specified account" do
    edition = create(:edition, :scheduled, scheduled_publication: 1.day.ago)
    robot_user = create(:scheduled_publishing_robot)
    Edition.publish_all_due_editions_as(robot_user)
    edition.reload
    assert edition.published?
  end

  test "#publish_all_due_editions_as records number of due publications to statsd" do
    edition = create(:edition, :scheduled, scheduled_publication: 1.day.ago)
    robot_user = create(:scheduled_publishing_robot)
    stats_collector = stub_everything("stats_collector")
    seq = sequence("publishing")
    stats_collector.expects(:gauge).with("scheduled_publishing.due", 1).in_sequence(seq)
    stats_collector.expects(:increment).with("scheduled_publishing.published").in_sequence(seq)
    stats_collector.expects(:gauge).with("scheduled_publishing.due", 0).in_sequence(seq)
    with_service(:stats_collector, stats_collector) do
      Edition.publish_all_due_editions_as(robot_user)
    end
  end

  test "#publish_all_due_editions_as sets transaction isolation level to SERIALIZABLE to ensure atomic update" do
    edition = create(:edition, :scheduled, scheduled_publication: 1.day.ago)
    robot_user = build(:scheduled_publishing_robot)

    atomic_publishing = sequence('atomic publishing')
    Edition.connection.expects(:execute).with("set transaction isolation level serializable").in_sequence(atomic_publishing)
    Edition.connection.expects(:transaction).returns(true).in_sequence(atomic_publishing)

    Edition.publish_all_due_editions_as(robot_user)
  end

  test "#publish_all_due_editions_as rescues exceptions raised by publish_as" do
    edition = build(:edition, title: "My doc")
    Edition.stubs(:due_for_publication).returns([edition])

    robot_user = stub("robot user", can_publish_scheduled_editions?: true)
    edition.stubs(:publish_as).raises(ActiveRecord::StatementInvalid)
  end

  test "#publish_all_due_editions_as updates the audit trail to indicate that the robot user published the edition" do
    edition = create(:edition, :scheduled, scheduled_publication: 1.day.ago)
    robot_user = create(:scheduled_publishing_robot)
    Edition.publish_all_due_editions_as(robot_user)
    publishing_event = edition.reload.edition_audit_trail.last
    assert_equal "publish", publishing_event.event
    assert_equal robot_user, publishing_event.actor
  end

  test "#publish_all_due_editions_as increments call_rate statsd counter" do
    stats_collector = stub_everything("stats_collector")
    stats_collector.expects(:increment).with("scheduled_publishing.call_rate").once
    with_service(:stats_collector, stats_collector) do
      Edition.publish_all_due_editions_as(stub("robot user"))
    end
  end
end
