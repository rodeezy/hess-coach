# Seeded metric types from spec section 7, in Julian's three assessment groups
# (MT-1). Two-sided types record left and right in one entry (MT-2). Everything
# starts switched off per client except body weight (MT-4).
module Seeds
  module MetricTypes
    # key, name, group, unit, two_sided, direction, decimals, best_of_three, computed
    TYPES = [
      # Biometric
      ["body_weight",   "Body Weight",        "biometric", "lb",    false, "neutral", 1],
      ["body_fat",      "Body Fat",           "biometric", "%",     false, "down",    1],
      ["ffmi",          "FFMI",               "biometric", "index", false, "up",      1, false, true],
      ["resting_hr",    "Resting Heart Rate", "biometric", "bpm",   false, "down",    0],
      ["hrv",           "HRV",                "biometric", "ms",    false, "up",      0],
      ["bp_systolic",   "Blood Pressure Systolic",  "biometric", "mmHg", false, "neutral", 0],
      ["bp_diastolic",  "Blood Pressure Diastolic", "biometric", "mmHg", false, "neutral", 0],
      ["circ_waist",    "Circumference: Waist", "biometric", "in", false, "neutral", 1],
      ["circ_hips",     "Circumference: Hips",  "biometric", "in", false, "neutral", 1],
      ["circ_chest",    "Circumference: Chest", "biometric", "in", false, "neutral", 1],
      ["circ_upper_arm", "Circumference: Upper Arm", "biometric", "in", true, "neutral", 1],
      ["circ_thigh",    "Circumference: Thigh", "biometric", "in", true, "neutral", 1],
      # Biometric, entered together from one DEXA scan (MT-9)
      ["lean_mass",     "Lean Mass",            "biometric", "lb",  false, "up",   1],
      ["fat_mass",      "Fat Mass",             "biometric", "lb",  false, "down", 1],
      ["visceral_fat",  "Visceral Fat",         "biometric", nil,   false, "down", 1],
      ["bone_density",  "Bone Mineral Density", "biometric", nil,   false, "up",   3],

      # Performance. Grip is the hand dynamometer, best of 3 per hand (MT-8).
      ["grip_strength", "Grip Strength",         "performance", "lb", true,  "up", 1, true],
      ["aerobic_5min",  "5 Minute Aerobic Test", "performance", nil,  false, "up", 1],
      ["aerobic_10min", "10 Minute Aerobic Test","performance", nil,  false, "up", 1],
      ["mb_chest_pass", "Med Ball Chest Pass",   "performance", "ft", false, "up", 1],
      ["vertical_leap", "Vertical Leap",         "performance", "in", false, "up", 1],
      ["broad_jump",    "Broad Jump",            "performance", "in", false, "up", 1],

      # Movement
      ["isa",            "ISA (infrasternal angle)", "movement", "degrees", false, "neutral", 0],
      ["shoulder_ir",    "Shoulder IR",    "movement", "degrees", true, "up", 0],
      ["shoulder_er",    "Shoulder ER",    "movement", "degrees", true, "up", 0],
      ["femur_ir",       "Femur IR",       "movement", "degrees", true, "up", 0],
      ["femur_er",       "Femur ER",       "movement", "degrees", true, "up", 0],
      ["hip_extension",  "Hip Extension",  "movement", "degrees", true, "up", 0],
      ["hip_adduction",  "Hip Adduction",  "movement", "degrees", true, "up", 0],
      ["ankle_mobility", "Ankle Mobility", "movement", "degrees", true, "up", 1],
      ["squat_score",    "Squat",          "movement", "score",   false, "up", 0],
      ["toe_touch",      "Toe Touch",      "movement", "score",   false, "up", 0],
      ["incline_pushup", "Incline Pushup", "movement", "reps",    false, "up", 0]
    ].freeze

    MASS_KEYS   = %w[body_weight lean_mass fat_mass grip_strength].freeze
    LENGTH_KEYS = %w[circ_waist circ_hips circ_chest circ_upper_arm circ_thigh
                     mb_chest_pass vertical_leap broad_jump ankle_mobility].freeze

    def self.measure_for(key)
      return "mass"   if MASS_KEYS.include?(key)
      return "length" if LENGTH_KEYS.include?(key)

      nil
    end

    # Entered together from one scan, with the source recorded as DEXA (MT-9).
    DEXA_KEYS = %w[body_fat lean_mass fat_mass visceral_fat bone_density].freeze

    # The only metric a new client tracks by default (MT-4).
    DEFAULT_TRACKED = %w[body_weight].freeze

    def self.call
      TYPES.each_with_index do |(key, name, group, unit, two_sided, direction, decimals,
                                best_of_three, computed), i|
        type = MetricType.find_or_initialize_by(trainer_id: nil, key: key)
        type.assign_attributes(
          name: name, group: group, unit: unit, direction: direction,
          decimals: decimals, is_two_sided: two_sided,
          is_best_of_three: !!best_of_three, is_computed: !!computed,
          measure: measure_for(key)
        )
        type.sort_order = i
        type.save!
      end
    end
  end
end
