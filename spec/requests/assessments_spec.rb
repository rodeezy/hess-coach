require "rails_helper"

RSpec.describe "Assessments", type: :request do
  include_context "seeded trainer"

  before do
    sign_in(trainer)
    %w[body_weight body_fat grip_strength shoulder_ir].each_with_index do |key, i|
      client.tracked_metrics.create!(metric_type: metric(key), sort_order: i)
    end
  end

  # The phase's acceptance criterion: a monthly assessment entered on one
  # screen, with left and right values for two-sided metrics (MT-6).
  it "saves a whole assessment in one call" do
    post client_assessment_path(client), params: {
      measured_on: "2026-03-01",
      source: "DEXA",
      entries: [
        { metric_type_id: metric("body_weight").id, value: "176.4" },
        { metric_type_id: metric("body_fat").id,    value: "15" },
        { metric_type_id: metric("grip_strength").id, attempts: %w[80 88 84],
          attempts_right: %w[95 99 97] },
        { metric_type_id: metric("shoulder_ir").id, value_left: "55", value_right: "60" }
      ]
    }

    expect(client.metric_entries.count).to eq(4)

    weight = client.metric_entries.find_by(metric_type: metric("body_weight"))
    expect(weight.value).to be_within(0.1).of(80.0) # stored canonical kg
    expect(weight.measured_on).to eq(Date.new(2026, 3, 1))

    # Best of three per hand becomes the value (MT-8).
    grip = client.metric_entries.find_by(metric_type: metric("grip_strength"))
    expect(grip.value_left).to be_within(0.1).of(39.9)  # 88 lb
    expect(grip.value_right).to be_within(0.1).of(44.9) # 99 lb
    expect(grip.attempts["left"]).to eq(%w[80 88 84])

    ir = client.metric_entries.find_by(metric_type: metric("shoulder_ir"))
    expect(ir.value_left.to_i).to eq(55)
    expect(ir.value_right.to_i).to eq(60)
  end

  it "records the scan source only on body composition metrics (MT-9)" do
    post client_assessment_path(client), params: {
      measured_on: "2026-03-01", source: "DEXA",
      entries: [
        { metric_type_id: metric("body_fat").id, value: "15" },
        { metric_type_id: metric("shoulder_ir").id, value_left: "55" }
      ]
    }

    expect(client.metric_entries.find_by(metric_type: metric("body_fat")).source).to eq("DEXA")
    expect(client.metric_entries.find_by(metric_type: metric("shoulder_ir")).source).to be_nil
  end

  it "skips blank rows rather than creating empty entries" do
    post client_assessment_path(client), params: {
      measured_on: "2026-03-01",
      entries: [
        { metric_type_id: metric("body_weight").id, value: "176.4" },
        { metric_type_id: metric("body_fat").id, value: "" },
        { metric_type_id: metric("grip_strength").id, attempts: ["", "", ""] }
      ]
    }

    expect(client.metric_entries.count).to eq(1)
  end

  it "overwrites rather than duplicating when the same date is saved twice" do
    2.times do |i|
      post client_assessment_path(client), params: {
        measured_on: "2026-03-01",
        entries: [{ metric_type_id: metric("body_weight").id, value: (170 + i).to_s }]
      }
    end

    expect(client.metric_entries.count).to eq(1)
    expect(client.metric_entries.first.value).to be_within(0.1).of(77.6) # 171 lb
  end

  # 404 rather than 403, so another trainer's client ids do not leak
  # (spec section 8, standard errors).
  it "404s on a client belonging to another trainer, and writes nothing" do
    other = Trainer.create!(email_address: "other@hess.test", password: "secret123")
    stranger = other.clients.create!(first_name: "Nope")

    post client_assessment_path(stranger), params: {
      measured_on: "2026-03-01",
      entries: [{ metric_type_id: metric("body_weight").id, value: "176.4" }]
    }

    expect(response).to have_http_status(:not_found)
    expect(stranger.metric_entries.count).to eq(0)
  end
end
