# Seed data from spec section 7. Nothing here is invented: the exercise library
# itself arrives as Julian's CSV export and is imported separately.
module Seeds
  module Lookups
    MAIN_PATTERNS = [
      %w[squat            Squat],
      %w[hinge            Hinge],
      %w[vertical_pull    Vertical\ Pull],
      %w[vertical_push    Vertical\ Push],
      %w[horizontal_push  Horizontal\ Push],
      %w[horizontal_pull  Horizontal\ Pull]
    ].freeze

    # The 16 groups weekly hard sets are counted against (spec 7).
    MUSCLE_GROUPS = [
      ["chest",           "Chest",           "upper"],
      ["front_delts",     "Front Delts",     "upper"],
      ["side_delts",      "Side Delts",      "upper"],
      ["rear_delts",      "Rear Delts",      "upper"],
      ["lats",            "Lats",            "upper"],
      ["upper_back",      "Upper Back",      "upper"],
      ["biceps",          "Biceps",          "upper"],
      ["triceps",         "Triceps",         "upper"],
      ["forearms_grip",   "Forearms/Grip",   "upper"],
      ["abs_obliques",    "Abs/Obliques",    "core"],
      ["spinal_erectors", "Spinal Erectors", "core"],
      ["glutes",          "Glutes",          "lower"],
      ["quads",           "Quads",           "lower"],
      ["hamstrings",      "Hamstrings",      "lower"],
      ["adductors",       "Adductors",       "lower"],
      ["calves",          "Calves",          "lower"]
    ].freeze

    # Open-ended by design: the app never advances a phase on its own (spec 3).
    PHASES = [
      { name: "Accumulation",    typical_min_weeks: 3, typical_max_weeks: 12, sweet_min_weeks: 6, sweet_max_weeks: 8 },
      { name: "Metabolic",       typical_min_weeks: 2, typical_max_weeks: 8,  sweet_min_weeks: 3, sweet_max_weeks: 6 },
      { name: "Intensification", typical_min_weeks: 3, typical_max_weeks: 8,  sweet_min_weeks: 4, sweet_max_weeks: 6 }
    ].freeze

    # Metabolic is deliberately blank: Julian has not sent those defaults yet, so
    # that phase prefills nothing (spec section 0). Blank cells prefill nothing.
    BLOCK_PRESETS = {
      "Accumulation" => {
        "strength"  => { sets_min: 3, sets_max: 3, reps_min: 8,  reps_max: 10,
                         rest_min_s: 60, rest_max_s: 120, rpe_min: 6, rpe_max: 8 },
        "accessory" => { sets_min: 2, sets_max: 3, reps_min: 15, reps_max: 15,
                         rest_min_s: 30, rest_max_s: 60 }
      },
      "Metabolic" => {},
      "Intensification" => {
        "strength"  => { sets_min: 3, sets_max: 6, reps_min: 3,  reps_max: 5 },
        "accessory" => { sets_min: 1, sets_max: 2, reps_min: 10, reps_max: 10,
                         rest_min_s: 60, rest_max_s: 90 }
      }
    }.freeze

    # Power is 1-3 x 1-3 and Neural Prep is 5-10 total reps across all phases (spec 3).
    UNIVERSAL_PRESETS = {
      "power"       => { sets_min: 1, sets_max: 3, reps_min: 1, reps_max: 3 },
      "neural_prep" => { note: "5 to 10 total reps" }
    }.freeze

    PRESENTATIONS = [
      ["wide_isa", "Wide ISA",
       "Exhalation to close ISA/IPA. Reaching to facilitate retraction and IR of ribcage",
       "Probably doesn't matter much, but more front loaded, exhalation based and IR driven"],
      ["narrow_isa", "Narrow ISA",
       "Inhalation to open ISA/IPA. Extension to facilitate ribcage ER",
       "Probably doesn't matter much, but more front loaded, exhalation based and ER driven"],
      ["limited_shoulder_ir", "Limited Shoulder IR",
       "Reaching. Protraction without spinal flexion. Upward rotation of scap",
       "Reaching activities. Limit back support on pressing. Add chest support on rowing. Inhalation into mid back"],
      ["limited_shoulder_er", "Limited Shoulder ER",
       "Shoulder extension. Scapular retraction without spinal extension",
       "Full back reference to maintain stacked torso. Eccentric orientation of pec. Inhalation into upper chest and sternum"],
      ["eccentric_hamstring", "Eccentric Hamstring Orientation",
       "Knee flexion in hip flexion",
       "Primarily knee flexion drills. Learning to control spinal position in hip extension"],
      ["concentric_hamstring", "Concentric Hamstring Orientation",
       "Hip extension in knee extension",
       "Primarily hip flexion in knee extension. Learning to control knee flexion without spinal compensation"],
      ["hingey_squat", "Hingey Squat",
       "Stacked torso in hip flexion",
       "Front load. Heel elevated. IR focused"],
      ["flexed_squat", "Flexed Squat",
       "Stacked torso in hip extension",
       "Back reference. Flat footed. ER focused"]
    ].freeze

    def self.call(trainer)
      MAIN_PATTERNS.each_with_index do |(key, name), i|
        MainPattern.find_or_create_by!(key: key) { |p| p.name = name; p.sort_order = i }
      end

      MUSCLE_GROUPS.each_with_index do |(key, name, region), i|
        MuscleGroup.find_or_create_by!(key: key) do |m|
          m.name = name; m.region = region; m.sort_order = i
        end
      end

      PHASES.each_with_index do |attrs, i|
        phase = trainer.phases.find_or_create_by!(name: attrs[:name]) do |p|
          p.assign_attributes(attrs.merge(sort_order: i))
        end

        BLOCK_PRESETS.fetch(attrs[:name], {}).each do |block, preset|
          trainer.block_presets.find_or_create_by!(phase: phase, block: block) do |bp|
            bp.assign_attributes(preset)
          end
        end

        UNIVERSAL_PRESETS.each do |block, preset|
          trainer.block_presets.find_or_create_by!(phase: phase, block: block) do |bp|
            bp.assign_attributes(preset)
          end
        end
      end

      PRESENTATIONS.each_with_index do |(key, name, prep, rule), i|
        trainer.presentations.find_or_create_by!(key: key) do |p|
          p.name = name
          p.movement_prep_focus = prep
          p.exercise_selection_rule = rule
          p.sort_order = i
        end
      end
    end
  end
end
