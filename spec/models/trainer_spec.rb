require "rails_helper"

RSpec.describe Trainer do
  it "normalizes and authenticates by email" do
    Trainer.create!(email_address: "  Julian@Example.COM ", password: "secret123")
    expect(Trainer.last.email_address).to eq("julian@example.com")
    expect(Trainer.authenticate_by(email_address: "julian@example.com", password: "secret123")).to be_present
    expect(Trainer.authenticate_by(email_address: "julian@example.com", password: "wrong")).to be_nil
  end

  it "defaults to Julian's settings from spec section 5" do
    t = Trainer.create!(email_address: "a@b.co", password: "secret123")
    expect(t.unit_system).to eq("lb")
    expect(t.e1rm_window_days).to eq(42)
    expect(t.report_cadence_days).to eq(56)
    expect(t.assessment_cadence_days).to eq(30)
  end
end
