class CreateTemplates < ActiveRecord::Migration[8.1]
  BLOCKS = %w[movement_prep neural_prep power strength accessory aerobic cool_down].freeze

  def block_check(column = "block")
    "#{column} IN (#{BLOCKS.map { |b| "'#{b}'" }.join(',')})"
  end

  def change
    # Per-phase, per-block prescription defaults. All numbers nullable: a blank
    # cell prefills nothing (spec 3, WB-2).
    create_table :block_presets, id: :uuid do |t|
      t.references :trainer,  null: false, foreign_key: true, type: :uuid
      t.references :phase,    null: false, foreign_key: true, type: :uuid
      t.string     :block,    null: false
      t.integer    :sets_min
      t.integer    :sets_max
      t.integer    :reps_min
      t.integer    :reps_max
      t.integer    :rest_min_s
      t.integer    :rest_max_s
      t.decimal    :rpe_min, precision: 3, scale: 1
      t.decimal    :rpe_max, precision: 3, scale: 1
      t.text       :note
      t.timestamps
    end
    add_index :block_presets, %i[phase_id block], unique: true
    add_check_constraint :block_presets, block_check, name: "block_presets_block_check"

    create_table :workout_templates, id: :uuid do |t|
      t.references :trainer,           null: false, foreign_key: true, type: :uuid
      t.string     :name,              null: false
      t.text       :description
      t.references :phase,             null: true, foreign_key: true, type: :uuid
      t.string     :program_name
      t.integer    :week_number
      t.integer    :day_number
      # null = reusable across clients (spec 5).
      t.references :client,            null: true, foreign_key: true, type: :uuid
      t.boolean    :is_block_template, null: false, default: false
      t.string     :block
      t.timestamps
    end
    add_index :workout_templates, %i[trainer_id client_id]
    add_check_constraint :workout_templates, "block IS NULL OR #{block_check}",
      name: "workout_templates_block_check"

    create_table :template_exercises, id: :uuid do |t|
      t.references :workout_template, null: false, foreign_key: true, type: :uuid
      t.references :exercise,         null: false, foreign_key: true, type: :uuid
      t.string     :block,            null: false
      t.integer    :position,         null: false, default: 0
      t.string     :group_label
      t.text       :notes
      t.integer    :rest_seconds
      t.string     :tempo
      # Display only: both are stored as RPE (spec WB-18).
      t.string     :effort_mode,      null: false, default: "rpe"
      t.string     :group_type
      t.integer    :group_rounds
      t.integer    :emom_total_s
      t.integer    :emom_interval_s
      # Aerobic Output rows only (spec WB-12).
      t.string     :energy_system
      t.string     :conditioning_method
      t.integer    :target_hr_pct
      t.timestamps
    end
    add_index :template_exercises, %i[workout_template_id block position],
      name: "index_template_exercises_on_template_block_position"
    add_check_constraint :template_exercises, block_check, name: "template_exercises_block_check"
    add_check_constraint :template_exercises, "effort_mode IN ('rpe','rir')",
      name: "template_exercises_effort_mode_check"
    add_check_constraint :template_exercises,
      "group_type IS NULL OR group_type IN ('superset','circuit','emom')",
      name: "template_exercises_group_type_check"
    add_check_constraint :template_exercises,
      "energy_system IS NULL OR energy_system IN ('aerobic','glycolytic','atp_pcr')",
      name: "template_exercises_energy_system_check"

    # One row per set even when every set matches, so "expand sets" is a
    # display toggle rather than a data migration (spec WB-5).
    create_table :template_sets, id: :uuid do |t|
      t.references :template_exercise, null: false, foreign_key: true, type: :uuid
      t.integer    :set_number,        null: false
      t.integer    :reps_min
      t.integer    :reps_max
      t.boolean    :is_amrap,          null: false, default: false
      t.integer    :duration_s
      t.decimal    :distance_m,     precision: 8, scale: 2
      t.decimal    :load_kg,        precision: 8, scale: 3
      t.decimal    :load_pct_e1rm,  precision: 5, scale: 2
      t.decimal    :rpe_target,     precision: 3, scale: 1
      t.timestamps
    end
    add_index :template_sets, %i[template_exercise_id set_number], unique: true
  end
end
