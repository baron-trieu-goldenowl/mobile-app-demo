require "rails_helper"

RSpec.describe Notifications::Deliver do
  let(:user) { create(:user) }

  it "creates a notification with its kind, data and English text" do
    notification = described_class.call(user, :calendar_synced, count: 12)

    expect(notification).to have_attributes(kind: "calendar_synced", data: { "count" => 12 },
                                            title: "Google Calendar synced",
                                            body: "Imported 12 new or updated events.")
  end

  it "skips a duplicate unread notification within the dedupe period" do
    described_class.call(user, :calendar_sync_failed, dedupe_for: 1.day)

    expect { described_class.call(user, :calendar_sync_failed, dedupe_for: 1.day) }
      .not_to change(Notification, :count)
  end

  it "notifies again once the previous one was read" do
    described_class.call(user, :calendar_sync_failed, dedupe_for: 1.day).update!(read: true)

    expect { described_class.call(user, :calendar_sync_failed, dedupe_for: 1.day) }
      .to change(Notification, :count).by(1)
  end
end
