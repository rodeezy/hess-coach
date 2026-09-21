# Fat-free mass index (spec 6.8). FFMI is never typed in: it is computed from a
# body fat entry plus the nearest body weight entry, so it only exists on dates
# where body fat was measured (MT-5).
#
#   FFM   = W * (1 - BF/100)
#   FFMI  = FFM / h^2
#   norm  = FFMI + 6.1 * (1.8 - h)
#
# W is kilograms, BF is percent, h is metres.
module Ffmi
  # Body weight must be within this many days of the body fat entry to be used.
  WEIGHT_WINDOW_DAYS = 7

  Point = Struct.new(:measured_on, :ffm_kg, :ffmi, :normalized, keyword_init: true)

  module_function

  def fat_free_mass_kg(weight_kg:, body_fat_pct:)
    return nil if weight_kg.blank? || body_fat_pct.blank?

    weight_kg.to_d * (1 - (body_fat_pct.to_d / 100))
  end

  def index(weight_kg:, body_fat_pct:, height_m:)
    return nil if height_m.blank? || height_m.to_d.zero?

    ffm = fat_free_mass_kg(weight_kg: weight_kg, body_fat_pct: body_fat_pct)
    return nil if ffm.nil?

    ffm / (height_m.to_d**2)
  end

  # Normalized to a 1.8 m frame, which is what gets displayed (spec 6.8).
  def normalized(weight_kg:, body_fat_pct:, height_m:)
    raw = index(weight_kg: weight_kg, body_fat_pct: body_fat_pct, height_m: height_m)
    return nil if raw.nil?

    raw + (BigDecimal("6.1") * (BigDecimal("1.8") - height_m.to_d))
  end

  # One point per date that has a body fat entry, using the weight entry closest
  # to that date within the window. Dates with no usable weight are skipped
  # rather than guessed at.
  #
  # body_fats and weights are [[Date, BigDecimal], ...].
  def series(body_fats:, weights:, height_m:)
    return [] if height_m.blank? || weights.empty?

    body_fats.filter_map do |measured_on, body_fat_pct|
      weight = nearest_weight(weights, measured_on)
      next if weight.nil?

      Point.new(
        measured_on: measured_on,
        ffm_kg:      fat_free_mass_kg(weight_kg: weight, body_fat_pct: body_fat_pct),
        ffmi:        index(weight_kg: weight, body_fat_pct: body_fat_pct, height_m: height_m),
        normalized:  normalized(weight_kg: weight, body_fat_pct: body_fat_pct, height_m: height_m)
      )
    end
  end

  def nearest_weight(weights, on_date)
    candidate = weights.min_by { |date, _| [(date - on_date).abs, (date - on_date)] }
    return nil if candidate.nil?
    return nil if (candidate.first - on_date).abs > WEIGHT_WINDOW_DAYS

    candidate.last
  end
end
