require "rails_helper"

RSpec.describe Ffmi do
  # The worked example from spec section 11.
  describe "the spec's worked example: 80 kg, 15% body fat, 1.75 m" do
    let(:args) { { weight_kg: 80, body_fat_pct: 15, height_m: BigDecimal("1.75") } }

    it "computes fat-free mass of 68.0 kg" do
      expect(described_class.fat_free_mass_kg(weight_kg: 80, body_fat_pct: 15).round(1))
        .to eq(BigDecimal("68.0"))
    end

    it "computes FFMI of 22.20" do
      expect(described_class.index(**args).round(2)).to eq(BigDecimal("22.20"))
    end

    it "computes a normalized FFMI of 22.5" do
      expect(described_class.normalized(**args).round(1)).to eq(BigDecimal("22.5"))
    end
  end

  it "returns nil rather than guessing when an input is missing" do
    expect(described_class.index(weight_kg: nil, body_fat_pct: 15, height_m: 1.75)).to be_nil
    expect(described_class.index(weight_kg: 80, body_fat_pct: nil, height_m: 1.75)).to be_nil
    expect(described_class.index(weight_kg: 80, body_fat_pct: 15, height_m: nil)).to be_nil
  end

  describe "series" do
    let(:height) { BigDecimal("1.75") }

    it "produces one point per body fat entry, using the nearest weight" do
      points = described_class.series(
        body_fats: [[Date.new(2026, 1, 10), BigDecimal("15")]],
        weights:   [[Date.new(2026, 1, 8), BigDecimal("80")],
                    [Date.new(2026, 2, 1), BigDecimal("90")]],
        height_m:  height
      )

      expect(points.size).to eq(1)
      expect(points.first.measured_on).to eq(Date.new(2026, 1, 10))
      expect(points.first.normalized.round(1)).to eq(BigDecimal("22.5"))
    end

    it "skips a body fat entry with no weight inside the 7 day window" do
      points = described_class.series(
        body_fats: [[Date.new(2026, 1, 10), BigDecimal("15")]],
        weights:   [[Date.new(2026, 1, 1), BigDecimal("80")]],
        height_m:  height
      )

      expect(points).to be_empty
    end

    it "accepts a weight exactly 7 days away" do
      points = described_class.series(
        body_fats: [[Date.new(2026, 1, 10), BigDecimal("15")]],
        weights:   [[Date.new(2026, 1, 3), BigDecimal("80")]],
        height_m:  height
      )

      expect(points.size).to eq(1)
    end

    it "returns nothing when the client has no height on file" do
      expect(described_class.series(
        body_fats: [[Date.new(2026, 1, 10), BigDecimal("15")]],
        weights:   [[Date.new(2026, 1, 10), BigDecimal("80")]],
        height_m:  nil
      )).to be_empty
    end
  end
end
