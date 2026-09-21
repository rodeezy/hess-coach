class CreateSessions < ActiveRecord::Migration[8.1]
  BLOCKS = %w[movement_prep neural_prep power strength accessory aerobic cool_down].freeze

  def block_check(column = "block")
    "#{column} IN (#{BLOCKS.map { |b| "'#{b}'" }.join(',')})"
  end

  def change
    # A dated instance of a workout. Planned values are copied in at creation so
    # later template edits never change history (spec SL-1).
    create_table :sessions, id: :uuid do |t|
      t.references :client,           null: false, foreign_key: true, type: :uuid
      t.references :workout_template, null: true, foreign_key: true, type: :uuid
      t.string     :name
      t.date       :session_date,     null: false
      t.references :phase,            null: true, foreign_key: true, type: :uuid
      t.string     :status,           null: false, default: "planned"
      t.text       :notes
      t.datetime   :started_at
      t.datetime   :completed_at
      t.timestamps
    end
    add_index :sessions, %i[client_id session_date]
    add_check_constraint :sessions,
      "status IN ('planned','in_progress','completed','skipped')", name: "sessions_status_check"

    create_table :session_exercises, id: :uuid do |t|
      t.references :session,             null: false, foreign_key: true, type: :uuid
      t.references :exercise,            null: false, foreign_key: true, type: :uuid
      # Set when swapped mid-session; the planned exercise is kept for
      # reference (spec SL-4).
      t.references :planned_exercise,    null: true, foreign_key: { to_table: :exercises }, type: :uuid
      t.string     :block,               null: false
      t.integer    :position,            null: false, default: 0
      t.string     :group_label
      t.text       :notes
      t.integer    :rest_seconds
      t.string     :tempo
      t.string     :effort_mode,         null: false, default: "rpe"
      t.string     :group_type
      t.integer    :group_rounds
      t.integer    :emom_total_s
      t.integer    :emom_interval_s
      t.string     :energy_system
      t.string     :conditioning_method
      t.integer    :target_hr_pct
      t.timestamps
    end
    add_index :session_exercises, %i[session_id block position],
      name: "index_session_exercises_on_session_block_position"
    add_check_constraint :session_exercises, block_check, name: "session_exercises_block_check"
    add_check_constraint :session_exercises, "effort_mode IN ('rpe','rir')",
      name: "session_exercises_effort_mode_check"
    add_check_constraint :session_exercises,
      "group_type IS NULL OR group_type IN ('superset','circuit','emom')",
      name: "session_exercises_group_type_check"
    add_check_constraint :session_exercises,
      "energy_system IS NULL OR energy_system IN ('aerobic','glycolytic','atp_pcr')",
      name: "session_exercises_energy_system_check"

    # The analytics fact table (spec 5).
    create_table :session_sets, id: :uuid do |t|
      t.references :session_exercise,   null: false, foreign_key: true, type: :uuid
      t.integer    :set_number,         null: false

      t.integer :planned_reps_min
      t.integer :planned_reps_max
      t.boolean :planned_is_amrap,   null: false, default: false
      t.integer :planned_duration_s
      t.decimal :planned_distance_m, precision: 8, scale: 2
      t.decimal :planned_load_kg,    precision: 8, scale: 3
      t.decimal :planned_rpe,        precision: 3, scale: 1

      t.integer :actual_reps
      t.integer :actual_duration_s
      t.decimal :actual_distance_m,  precision: 8, scale: 2
      t.decimal :actual_load_kg,     precision: 8, scale: 3
      t.decimal :actual_rpe,         precision: 3, scale: 1

      # Drops and clusters are tagged in the moment, never planned (spec SL-13).
      t.string     :technique,  null: false, default: "none"
      t.references :parent_set, null: true, foreign_key: { to_table: :session_sets }, type: :uuid
      t.decimal    :velocity_mps, precision: 5, scale: 3
      # Stays false: there is no warm-up set type in the MVP interface (spec SL-15).
      t.boolean    :is_warmup,  null: false, default: false
      t.string     :status,     null: false, default: "pending"

      # Computed by the server on write. effective_load_kg is frozen at write
      # time so later body weight entries never rewrite history (spec 6.1).
      t.decimal :effective_load_kg, precision: 8, scale: 3
      t.decimal :e1rm_kg,           precision: 8, scale: 3
      t.decimal :volume_kg,         precision: 10, scale: 3

      # Offline sync: the browser stamps this so replayed writes resolve
      # last-write-wins without a server round trip (spec 8, Sets).
      t.datetime :client_updated_at

      t.timestamps
    end
    add_index :session_sets, %i[session_exercise_id set_number],
      name: "index_session_sets_on_exercise_and_number"
    add_check_constraint :session_sets, "technique IN ('none','drop','cluster')",
      name: "session_sets_technique_check"
    add_check_constraint :session_sets, "status IN ('pending','done','skipped')",
      name: "session_sets_status_check"

    # One row per client per date (spec 5).
    create_table :readiness_entries, id: :uuid do |t|
      t.references :client,     null: false, foreign_key: true, type: :uuid
      t.date       :entry_date, null: false
      t.references :session,    null: true, foreign_key: true, type: :uuid
      t.integer    :rhr
      t.integer    :hrv
      t.integer    :readiness
      t.integer    :sleep
      t.integer    :nutrition
      t.integer    :hydration
      t.timestamps
    end
    add_index :readiness_entries, %i[client_id entry_date], unique: true
    %w[readiness sleep nutrition hydration].each do |col|
      add_check_constraint :readiness_entries,
        "#{col} IS NULL OR (#{col} BETWEEN 1 AND 5)", name: "readiness_entries_#{col}_check"
    end
  end
end
