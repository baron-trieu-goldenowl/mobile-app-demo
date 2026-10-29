require "rails_helper"

RSpec.describe WakeLogs::StreakMilestone do
  let(:user) { create(:user) }
  let(:vietnam) { 7.hours.to_i }

  # Wakes at 06:00 Vietnam time (23:00 UTC the previous day).
  def wake(days_ago, hour: 6)
    time = (Time.utc(2026, 10, 29, hour) - days_ago.days) - vietnam
    user.wake_logs.create!(dismissed_at: time, snooze_count: 0)
  end

  it "celebrates the third day in a row, counted in the device time zone" do
    wake(2)
    wake(1)

    notification = described_class.call(wake(0), utc_offset: vietnam)

    expect(notification).to have_attributes(kind: "wake_streak", data: { "days" => 3 })
  end

  it "ignores streaks that are not a milestone" do
    wake(1)

    expect(described_class.call(wake(0), utc_offset: vietnam)).to be_nil
  end

  it "only counts the first wake-up of the day" do
    wake(2)
    wake(1)
    described_class.call(wake(0), utc_offset: vietnam)

    expect(described_class.call(wake(0, hour: 14), utc_offset: vietnam)).to be_nil
  end

  it "stops counting at a missed day" do
    wake(3)
    wake(1)

    expect(described_class.call(wake(0), utc_offset: vietnam)).to be_nil
  end
end
