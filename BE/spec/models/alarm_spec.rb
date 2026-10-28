require "rails_helper"

RSpec.describe Alarm do
  subject(:alarm) { build(:alarm) }

  it { is_expected.to be_valid }

  it "rejects malformed times" do
    alarm.time = "6:30"
    expect(alarm).not_to be_valid
  end

  it "normalizes repeat days" do
    alarm.repeat_days = %w[5 1 1]
    alarm.validate
    expect(alarm.repeat_days).to eq([1, 5])
  end

  it "rejects days outside 1..7" do
    alarm.repeat_days = [0, 8]
    expect(alarm).not_to be_valid
  end

  it "requires a registered code for the QR mission" do
    alarm.challenge_type = "qr"
    expect(alarm).not_to be_valid
    alarm.qr_code = "1234567890"
    expect(alarm).to be_valid
  end
end
