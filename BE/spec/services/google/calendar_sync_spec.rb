require "rails_helper"

RSpec.describe Google::CalendarSync do
  let(:user) do
    create(:user, google_refresh_token: "refresh", google_access_token: "access",
                  google_token_expires_at: 1.hour.from_now)
  end
  let(:events_url) { %r{googleapis.com/calendar/v3/calendars/primary/events} }

  it "notifies how many events were imported" do
    item = { id: "g1", summary: "Standup", start: { dateTime: 1.day.from_now.iso8601 } }
    stub_request(:get, events_url).to_return_json(body: { items: [item] })

    expect(described_class.call(user)).to eq(1)
    expect(user.notifications.last).to have_attributes(kind: "calendar_synced", data: { "count" => 1 })
  end

  it "does not notify when nothing changed" do
    stub_request(:get, events_url).to_return_json(body: { items: [] })

    expect { described_class.call(user) }.not_to change(Notification, :count)
  end

  it "notifies once when the sync keeps failing" do
    stub_request(:get, events_url).to_return(status: 403, body: { error: { message: "API disabled" } }.to_json)

    2.times { expect { described_class.call(user) }.to raise_error(Google::Error) }
    expect(user.notifications.pluck(:kind)).to eq(["calendar_sync_failed"])
  end
end
