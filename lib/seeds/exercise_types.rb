# Exercise type defaults from spec section 7. These are what make categorisation
# automatic (EX-3): the type sets the main pattern an exercise rolls up to, its
# default session block, prescription style and muscle groups.
module Seeds
  module ExerciseTypes
    # key, name, group, main_pattern, default_block, prescription, menu_category,
    # primary muscles, secondary muscles
    TYPES = [
      ["horizontal_push", "Horizontal Push", "strength", "horizontal_push", "strength", "reps", "hor_push",
       %w[chest], %w[front_delts triceps]],
      ["horizontal_pull", "Horizontal Pull", "strength", "horizontal_pull", "strength", "reps", "hor_pull",
       %w[upper_back lats], %w[rear_delts biceps]],
      ["vertical_push", "Vertical Push", "strength", "vertical_push", "strength", "reps", "vert_push",
       %w[front_delts], %w[triceps side_delts]],
      ["vertical_pull", "Vertical Pull", "strength", "vertical_pull", "strength", "reps", "vert_pull",
       %w[lats], %w[biceps upper_back forearms_grip]],
      ["squat_bilateral", "Squat (bilateral)", "strength", "squat", "strength", "reps", "knee_dominant",
       %w[quads glutes], %w[adductors]],
      ["squat_unilateral", "Squat (unilateral)", "strength", "squat", "accessory", "reps", "knee_dominant",
       %w[quads glutes], %w[adductors]],
      ["hinge_bilateral", "Hinge (bilateral)", "strength", "hinge", "strength", "reps", "hip_dominant",
       %w[glutes hamstrings], %w[spinal_erectors]],
      ["hinge_unilateral", "Hinge (unilateral)", "strength", "hinge", "accessory", "reps", "hip_dominant",
       %w[glutes hamstrings], %w[spinal_erectors]],
      ["bridge_thrust", "Bridge/Thrust", "strength", nil, "accessory", "reps", "hip_dominant",
       %w[glutes], %w[hamstrings]],
      ["isolation_biceps", "Isolation - Biceps", "isolation", nil, "accessory", "reps", nil,
       %w[biceps], %w[forearms_grip]],
      ["isolation_triceps", "Isolation - Triceps", "isolation", nil, "accessory", "reps", nil,
       %w[triceps], []],
      ["isolation_shoulders", "Isolation - Shoulders", "isolation", nil, "accessory", "reps", nil,
       %w[side_delts], []],
      ["isolation_calves", "Isolation - Calves", "isolation", nil, "accessory", "reps", nil,
       %w[calves], []],
      ["isolation_quads", "Isolation - Quads", "isolation", nil, "accessory", "reps", nil,
       %w[quads], []],
      ["isolation_hamstrings", "Isolation - Hamstrings", "isolation", nil, "accessory", "reps", nil,
       %w[hamstrings], []],
      ["abs", "Abs", "core", nil, "accessory", "reps", "trunk", %w[abs_obliques], []],
      ["throws", "Throws", "power", nil, "neural_prep", "reps", nil, [], []],
      ["plyometrics", "Plyometrics", "power", nil, "neural_prep", "reps", nil, [], []],
      ["isometrics", "Isometrics", "isometric", nil, "movement_prep", "time", nil, [], []],
      ["mobility", "Mobility", "mobility", nil, "movement_prep", "reps", nil, [], []],
      # The methodology programs these two blocks but the sheet has no exercises
      # for either, so they are seeded with starters from the training model (spec 7).
      ["power", "Power", "power", nil, "power", "reps", nil, [], []],
      ["aerobic_output", "Aerobic Output", "aerobic", nil, "aerobic", "time", nil, [], []]
    ].freeze

    # One type per body area, all Movement Prep (spec 7).
    MORNING_AREAS = ["Hip", "Pelvis", "Spine", "Neck", "Shoulder Blade", "Shoulder",
                     "Elbow", "Wrist", "Knee", "Ankles"].freeze

    # Starters for the two blocks the sheet does not cover (spec 7).
    EXTRA_EXERCISES = {
      "power" => ["Barbell Clean Pull", "Power Clean", "Power Snatch", "Trap Bar Jump",
                  "Box Jump", "Vertical Jump", "Broad Jump", "Double Broad Jump",
                  "Triple Broad Jump", "Depth Drop", "MB Overhead Throw", "MB Rotational Throw"],
      "aerobic_output" => ["Sled Pull", "Prowler Push", "Assault Bike", "Walking"]
    }.freeze

    def self.call(trainer = nil)
      patterns = MainPattern.pluck(:key, :id).to_h
      muscles  = MuscleGroup.pluck(:key, :id).to_h
      order    = 0

      TYPES.each do |key, name, group, pattern, block, presc, menu, primary, secondary|
        type = ExerciseType.find_or_initialize_by(key: key)
        type.assign_attributes(
          name: name, group: group, main_pattern_id: pattern && patterns.fetch(pattern),
          default_block: block, default_prescription: presc,
          menu_category: menu, sort_order: order
        )
        type.save!
        order += 1
        apply_muscles(type, primary, secondary, muscles)
      end

      MORNING_AREAS.each do |area|
        key  = "morning_mobilization_#{area.parameterize(separator: '_')}"
        type = ExerciseType.find_or_initialize_by(key: key)
        type.assign_attributes(
          name: "Morning Mobilizations - #{area}", group: "morning_mobilization",
          main_pattern_id: nil, default_block: "movement_prep",
          default_prescription: "reps", body_area: area, sort_order: order
        )
        type.save!
        order += 1
      end

      seed_extra_exercises(trainer) if trainer
    end

    # The sheet has no Power or Aerobic Output rows, so those two blocks would be
    # unusable on day one without these (spec 7).
    def self.seed_extra_exercises(trainer)
      EXTRA_EXERCISES.each do |type_key, names|
        type = ExerciseType.find_by!(key: type_key)
        names.each_with_index do |name, i|
          ex = trainer.exercises.find_or_initialize_by(exercise_type_id: type.id, name: name)
          next unless ex.new_record?

          ex.assign_attributes(
            sort_order: i, prescription: type.default_prescription,
            needs_video: true, e1rm_eligible: false,
            load_type: type_key == "aerobic_output" ? "none" : "external"
          )
          ex.save!
        end
      end
    end

    def self.apply_muscles(type, primary, secondary, muscles)
      wanted = primary.map { |k| [muscles.fetch(k), "primary"] } +
               secondary.map { |k| [muscles.fetch(k), "secondary"] }
      wanted.each do |muscle_group_id, role|
        row = ExerciseTypeMuscleGroup.find_or_initialize_by(
          exercise_type: type, muscle_group_id: muscle_group_id
        )
        row.role = role
        row.save!
      end
    end
  end
end
