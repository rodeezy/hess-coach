require "rails_helper"

RSpec.describe MetricPresenter do
  include_context "seeded trainer"

  def track(*keys)
    keys.each_with_index do |key, i|
      client.tracked_metrics.create!(metric_type: metric(key), sort_order: i)
    end
  end

  def tiles(unit_system: "imperial")
    described_class.new(client: client, unit_system: unit_system).tiles
  end

  it "converts stored kilograms into the trainer's display unit" do
    track("body_weight")
    record("body_weight", value: BigDecimal("80")) # stored canonical: kg

    imperial = tiles.first
    metric_units = tiles(unit_system: "metric").first

    expect(imperial[:unit]).to eq("lb")
    expect(imperial[:latest][:value]).to be_within(0.1).of(176.4)
    expect(metric_units[:unit]).to eq("kg")
    expect(metric_units[:latest][:value]).to be_within(0.1).of(80.0)
  end

  it "charts a two-sided metric as left and right (MT-2)" do
    track("grip_strength")
    record("grip_strength", left: BigDecimal("40"), right: BigDecimal("45"))

    tile = tiles.first
    expect(tile[:twoSided]).to be(true)
    expect(tile[:latest][:left]).to be_within(0.1).of(88.2)
    expect(tile[:latest][:right]).to be_within(0.1).of(99.2)
  end

  it "derives FFMI from body fat plus the nearest weight (MT-5, 6.8)" do
    track("ffmi")
    record("body_weight", value: BigDecimal("80"), on: Date.new(2026, 3, 1))
    record("body_fat",    value: BigDecimal("15"), on: Date.new(2026, 3, 3))

    tile = tiles.first
    expect(tile[:computed]).to be(true)
    expect(tile[:points].size).to eq(1)
    expect(tile[:latest][:value]).to eq(22.5) # normalized, spec's worked example
  end

  it "produces no FFMI without a height on file" do
    client.update!(height_cm: nil)
    track("ffmi")
    record("body_weight", value: BigDecimal("80"))
    record("body_fat",    value: BigDecimal("15"))

    expect(tiles.first[:points]).to be_empty
  end

  it "reports the change between the last two entries" do
    track("body_weight")
    record("body_weight", value: BigDecimal("80"), on: Date.current - 30)
    record("body_weight", value: BigDecimal("78"), on: Date.current)

    expect(tiles.first[:change][:value]).to be < 0
  end

  it "shows only the metrics this client tracks (MT-4)" do
    track("body_weight")
    expect(tiles.map { |t| t[:key] }).to eq(["body_weight"])
  end
end
