# Conversion happens at the edges only (spec section 2). Storage is canonical:
# kilograms for mass, centimetres for length.
module Units
  KG_PER_LB = BigDecimal("0.45359237")
  CM_PER_IN = BigDecimal("2.54")

  module_function

  def to_canonical(value, measure:, unit_system:)
    return nil if value.blank?
    return value.to_d if measure.nil? || unit_system == "metric"

    case measure
    when "mass"   then value.to_d * KG_PER_LB
    when "length" then value.to_d * CM_PER_IN
    else value.to_d
    end
  end

  def to_display(value, measure:, unit_system:)
    return nil if value.blank?
    return value.to_d if measure.nil? || unit_system == "metric"

    case measure
    when "mass"   then value.to_d / KG_PER_LB
    when "length" then value.to_d / CM_PER_IN
    else value.to_d
    end
  end

  def unit_label(measure:, unit_system:, fallback: nil)
    case measure
    when "mass"   then unit_system == "metric" ? "kg" : "lb"
    when "length" then unit_system == "metric" ? "cm" : "in"
    else fallback
    end
  end
end
