# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_20_240007) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "auth_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.uuid "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["trainer_id"], name: "index_auth_sessions_on_trainer_id"
  end

  create_table "block_presets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "block", null: false
    t.datetime "created_at", null: false
    t.text "note"
    t.uuid "phase_id", null: false
    t.integer "reps_max"
    t.integer "reps_min"
    t.integer "rest_max_s"
    t.integer "rest_min_s"
    t.decimal "rpe_max", precision: 3, scale: 1
    t.decimal "rpe_min", precision: 3, scale: 1
    t.integer "sets_max"
    t.integer "sets_min"
    t.uuid "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["phase_id", "block"], name: "index_block_presets_on_phase_id_and_block", unique: true
    t.index ["phase_id"], name: "index_block_presets_on_phase_id"
    t.index ["trainer_id"], name: "index_block_presets_on_trainer_id"
    t.check_constraint "block::text = ANY (ARRAY['movement_prep'::character varying::text, 'neural_prep'::character varying::text, 'power'::character varying::text, 'strength'::character varying::text, 'accessory'::character varying::text, 'aerobic'::character varying::text, 'cool_down'::character varying::text])", name: "block_presets_block_check"
  end

  create_table "client_menu_exercises", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "added_on", null: false
    t.uuid "client_id", null: false
    t.datetime "created_at", null: false
    t.uuid "exercise_id", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "exercise_id"], name: "index_cme_on_client_and_exercise", unique: true
    t.index ["client_id"], name: "index_client_menu_exercises_on_client_id"
    t.index ["exercise_id"], name: "index_client_menu_exercises_on_exercise_id"
  end

  create_table "client_pattern_benchmarks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.datetime "created_at", null: false
    t.date "effective_from", null: false
    t.uuid "exercise_id", null: false
    t.uuid "main_pattern_id", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "main_pattern_id", "effective_from"], name: "index_cpb_on_client_pattern_effective"
    t.index ["client_id"], name: "index_client_pattern_benchmarks_on_client_id"
    t.index ["exercise_id"], name: "index_client_pattern_benchmarks_on_exercise_id"
    t.index ["main_pattern_id"], name: "index_client_pattern_benchmarks_on_main_pattern_id"
  end

  create_table "client_presentations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.datetime "created_at", null: false
    t.text "note"
    t.date "noted_on", null: false
    t.uuid "presentation_id", null: false
    t.date "resolved_on"
    t.datetime "updated_at", null: false
    t.index ["client_id", "presentation_id", "resolved_on"], name: "index_cp_on_client_presentation_resolved"
    t.index ["client_id"], name: "index_client_presentations_on_client_id"
    t.index ["presentation_id"], name: "index_client_presentations_on_presentation_id"
  end

  create_table "client_tracked_metrics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.datetime "created_at", null: false
    t.uuid "metric_type_id", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "metric_type_id"], name: "index_ctm_on_client_and_metric_type", unique: true
    t.index ["client_id"], name: "index_client_tracked_metrics_on_client_id"
    t.index ["metric_type_id"], name: "index_client_tracked_metrics_on_metric_type_id"
  end

  create_table "clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "current_phase_id"
    t.date "date_of_birth"
    t.string "disc_type"
    t.string "email"
    t.string "first_name", null: false
    t.decimal "height_cm", precision: 6, scale: 2
    t.text "intake_notes"
    t.string "last_name"
    t.integer "max_hr"
    t.date "phase_started_on"
    t.string "phone"
    t.integer "report_cadence_days"
    t.string "sex"
    t.date "start_date"
    t.string "status", default: "active", null: false
    t.uuid "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "uses_power_block", default: false, null: false
    t.boolean "uses_vbt", default: false, null: false
    t.index ["current_phase_id"], name: "index_clients_on_current_phase_id"
    t.index ["trainer_id", "status"], name: "index_clients_on_trainer_id_and_status"
    t.index ["trainer_id"], name: "index_clients_on_trainer_id"
    t.check_constraint "disc_type IS NULL OR (disc_type::text = ANY (ARRAY['D'::character varying::text, 'i'::character varying::text, 'S'::character varying::text, 'C'::character varying::text]))", name: "clients_disc_type_check"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'archived'::character varying::text])", name: "clients_status_check"
  end

  create_table "exercise_muscle_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "exercise_id", null: false
    t.uuid "muscle_group_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id", "muscle_group_id"], name: "index_emg_on_exercise_and_group", unique: true
    t.index ["exercise_id"], name: "index_exercise_muscle_groups_on_exercise_id"
    t.index ["muscle_group_id"], name: "index_exercise_muscle_groups_on_muscle_group_id"
    t.check_constraint "role::text = ANY (ARRAY['primary'::character varying::text, 'secondary'::character varying::text])", name: "emg_role_check"
  end

  create_table "exercise_type_muscle_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "exercise_type_id", null: false
    t.uuid "muscle_group_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_type_id", "muscle_group_id"], name: "index_etmg_on_type_and_group", unique: true
    t.index ["exercise_type_id"], name: "index_exercise_type_muscle_groups_on_exercise_type_id"
    t.index ["muscle_group_id"], name: "index_exercise_type_muscle_groups_on_muscle_group_id"
    t.check_constraint "role::text = ANY (ARRAY['primary'::character varying::text, 'secondary'::character varying::text])", name: "etmg_role_check"
  end

  create_table "exercise_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "body_area"
    t.datetime "created_at", null: false
    t.string "default_block", null: false
    t.string "default_prescription", default: "reps", null: false
    t.string "group", null: false
    t.string "key", null: false
    t.uuid "main_pattern_id"
    t.string "menu_category"
    t.string "name", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_exercise_types_on_key", unique: true
    t.index ["main_pattern_id"], name: "index_exercise_types_on_main_pattern_id"
    t.check_constraint "default_block::text = ANY (ARRAY['movement_prep'::character varying::text, 'neural_prep'::character varying::text, 'power'::character varying::text, 'strength'::character varying::text, 'accessory'::character varying::text, 'aerobic'::character varying::text, 'cool_down'::character varying::text])", name: "exercise_types_default_block_check"
    t.check_constraint "default_prescription::text = ANY (ARRAY['reps'::character varying::text, 'time'::character varying::text, 'distance'::character varying::text])", name: "exercise_types_default_prescription_check"
  end

  create_table "exercises", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "e1rm_eligible", default: false, null: false
    t.uuid "exercise_type_id", null: false
    t.integer "implement_count", default: 1, null: false
    t.text "instructions"
    t.boolean "is_archived", default: false, null: false
    t.boolean "is_unilateral", default: false, null: false
    t.string "load_type", default: "external", null: false
    t.string "name", null: false
    t.boolean "needs_video", default: false, null: false
    t.boolean "on_menu", default: false, null: false
    t.string "prescription", default: "reps", null: false
    t.integer "sort_order", default: 0, null: false
    t.uuid "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.index "trainer_id, lower((name)::text), exercise_type_id", name: "index_exercises_on_trainer_lower_name_type", unique: true
    t.index ["exercise_type_id", "sort_order"], name: "index_exercises_on_exercise_type_id_and_sort_order"
    t.index ["exercise_type_id"], name: "index_exercises_on_exercise_type_id"
    t.index ["trainer_id"], name: "index_exercises_on_trainer_id"
    t.check_constraint "implement_count > 0", name: "exercises_implement_count_check"
    t.check_constraint "load_type::text = ANY (ARRAY['external'::character varying::text, 'bodyweight'::character varying::text, 'bodyweight_plus'::character varying::text, 'assisted'::character varying::text, 'none'::character varying::text])", name: "exercises_load_type_check"
    t.check_constraint "prescription::text = ANY (ARRAY['reps'::character varying::text, 'time'::character varying::text, 'distance'::character varying::text])", name: "exercises_prescription_check"
  end

  create_table "goals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "category", default: "performance", null: false
    t.uuid "client_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "kind", default: "qualitative", null: false
    t.uuid "main_pattern_id"
    t.string "metric_side"
    t.uuid "metric_type_id"
    t.date "start_date"
    t.decimal "start_value", precision: 10, scale: 3
    t.string "status", default: "active", null: false
    t.date "target_date"
    t.decimal "target_value", precision: 10, scale: 3
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "status"], name: "index_goals_on_client_id_and_status"
    t.index ["client_id"], name: "index_goals_on_client_id"
    t.index ["main_pattern_id"], name: "index_goals_on_main_pattern_id"
    t.index ["metric_type_id"], name: "index_goals_on_metric_type_id"
    t.check_constraint "category::text = ANY (ARRAY['performance'::character varying::text, 'body_comp'::character varying::text, 'movement'::character varying::text, 'lifestyle'::character varying::text])", name: "goals_category_check"
    t.check_constraint "kind::text = ANY (ARRAY['metric'::character varying::text, 'pattern_e1rm'::character varying::text, 'qualitative'::character varying::text])", name: "goals_kind_check"
    t.check_constraint "metric_side IS NULL OR (metric_side::text = ANY (ARRAY['left'::character varying::text, 'right'::character varying::text]))", name: "goals_metric_side_check"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'achieved'::character varying::text, 'paused'::character varying::text, 'dropped'::character varying::text])", name: "goals_status_check"
  end

  create_table "main_patterns", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_main_patterns_on_key", unique: true
  end

  create_table "metric_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "attempts"
    t.uuid "client_id", null: false
    t.datetime "created_at", null: false
    t.date "measured_on", null: false
    t.uuid "metric_type_id", null: false
    t.text "note"
    t.string "source"
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 10, scale: 3
    t.decimal "value_left", precision: 10, scale: 3
    t.decimal "value_right", precision: 10, scale: 3
    t.index ["client_id", "metric_type_id", "measured_on"], name: "index_metric_entries_on_client_type_date"
    t.index ["client_id"], name: "index_metric_entries_on_client_id"
    t.index ["metric_type_id"], name: "index_metric_entries_on_metric_type_id"
  end

  create_table "metric_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "decimals", default: 1, null: false
    t.string "direction", default: "neutral", null: false
    t.string "group", null: false
    t.boolean "is_best_of_three", default: false, null: false
    t.boolean "is_computed", default: false, null: false
    t.boolean "is_two_sided", default: false, null: false
    t.string "key", null: false
    t.string "name", null: false
    t.uuid "trainer_id"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["trainer_id", "key"], name: "index_metric_types_on_trainer_id_and_key", unique: true
    t.index ["trainer_id"], name: "index_metric_types_on_trainer_id"
    t.check_constraint "\"group\"::text = ANY (ARRAY['biometric'::character varying::text, 'performance'::character varying::text, 'movement'::character varying::text])", name: "metric_types_group_check"
    t.check_constraint "direction::text = ANY (ARRAY['up'::character varying::text, 'down'::character varying::text, 'neutral'::character varying::text])", name: "metric_types_direction_check"
  end

  create_table "muscle_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.string "region", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_muscle_groups_on_key", unique: true
    t.check_constraint "region::text = ANY (ARRAY['upper'::character varying::text, 'lower'::character varying::text, 'core'::character varying::text])", name: "muscle_groups_region_check"
  end

  create_table "notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body", null: false
    t.uuid "client_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_pinned", default: false, null: false
    t.datetime "noted_at", null: false
    t.string "tag"
    t.datetime "updated_at", null: false
    t.index ["client_id", "is_pinned", "noted_at"], name: "index_notes_on_client_id_and_is_pinned_and_noted_at"
    t.index ["client_id"], name: "index_notes_on_client_id"
    t.check_constraint "tag IS NULL OR (tag::text = ANY (ARRAY['injury'::character varying::text, 'preference'::character varying::text, 'lifestyle'::character varying::text, 'program'::character varying::text, 'general'::character varying::text]))", name: "notes_tag_check"
  end

  create_table "phases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_archived", default: false, null: false
    t.string "name", null: false
    t.integer "sort_order", default: 0, null: false
    t.integer "sweet_max_weeks"
    t.integer "sweet_min_weeks"
    t.uuid "trainer_id", null: false
    t.integer "typical_max_weeks"
    t.integer "typical_min_weeks"
    t.datetime "updated_at", null: false
    t.index ["trainer_id", "sort_order"], name: "index_phases_on_trainer_id_and_sort_order"
    t.index ["trainer_id"], name: "index_phases_on_trainer_id"
  end

  create_table "presentations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "exercise_selection_rule"
    t.string "key", null: false
    t.text "movement_prep_focus"
    t.string "name", null: false
    t.integer "sort_order", default: 0, null: false
    t.uuid "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["trainer_id", "key"], name: "index_presentations_on_trainer_id_and_key", unique: true
    t.index ["trainer_id"], name: "index_presentations_on_trainer_id"
  end

  create_table "readiness_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.datetime "created_at", null: false
    t.date "entry_date", null: false
    t.integer "hrv"
    t.integer "hydration"
    t.integer "nutrition"
    t.integer "readiness"
    t.integer "rhr"
    t.uuid "session_id"
    t.integer "sleep"
    t.datetime "updated_at", null: false
    t.index ["client_id", "entry_date"], name: "index_readiness_entries_on_client_id_and_entry_date", unique: true
    t.index ["client_id"], name: "index_readiness_entries_on_client_id"
    t.index ["session_id"], name: "index_readiness_entries_on_session_id"
    t.check_constraint "hydration IS NULL OR hydration >= 1 AND hydration <= 5", name: "readiness_entries_hydration_check"
    t.check_constraint "nutrition IS NULL OR nutrition >= 1 AND nutrition <= 5", name: "readiness_entries_nutrition_check"
    t.check_constraint "readiness IS NULL OR readiness >= 1 AND readiness <= 5", name: "readiness_entries_readiness_check"
    t.check_constraint "sleep IS NULL OR sleep >= 1 AND sleep <= 5", name: "readiness_entries_sleep_check"
  end

  create_table "reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.text "coach_summary"
    t.datetime "created_at", null: false
    t.jsonb "goal_comments"
    t.jsonb "hidden_sections"
    t.text "next_focus"
    t.date "period_end", null: false
    t.date "period_start", null: false
    t.datetime "published_at"
    t.datetime "sent_at"
    t.string "share_token", null: false
    t.jsonb "snapshot"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "period_end"], name: "index_reports_on_client_id_and_period_end"
    t.index ["client_id"], name: "index_reports_on_client_id"
    t.index ["share_token"], name: "index_reports_on_share_token", unique: true
    t.check_constraint "period_end >= period_start", name: "reports_period_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'published'::character varying::text])", name: "reports_status_check"
  end

  create_table "session_exercises", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "block", null: false
    t.string "conditioning_method"
    t.datetime "created_at", null: false
    t.string "effort_mode", default: "rpe", null: false
    t.integer "emom_interval_s"
    t.integer "emom_total_s"
    t.string "energy_system"
    t.uuid "exercise_id", null: false
    t.string "group_label"
    t.integer "group_rounds"
    t.string "group_type"
    t.text "notes"
    t.uuid "planned_exercise_id"
    t.integer "position", default: 0, null: false
    t.integer "rest_seconds"
    t.uuid "session_id", null: false
    t.integer "target_hr_pct"
    t.string "tempo"
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_session_exercises_on_exercise_id"
    t.index ["planned_exercise_id"], name: "index_session_exercises_on_planned_exercise_id"
    t.index ["session_id", "block", "position"], name: "index_session_exercises_on_session_block_position"
    t.index ["session_id"], name: "index_session_exercises_on_session_id"
    t.check_constraint "block::text = ANY (ARRAY['movement_prep'::character varying::text, 'neural_prep'::character varying::text, 'power'::character varying::text, 'strength'::character varying::text, 'accessory'::character varying::text, 'aerobic'::character varying::text, 'cool_down'::character varying::text])", name: "session_exercises_block_check"
    t.check_constraint "effort_mode::text = ANY (ARRAY['rpe'::character varying::text, 'rir'::character varying::text])", name: "session_exercises_effort_mode_check"
    t.check_constraint "energy_system IS NULL OR (energy_system::text = ANY (ARRAY['aerobic'::character varying::text, 'glycolytic'::character varying::text, 'atp_pcr'::character varying::text]))", name: "session_exercises_energy_system_check"
    t.check_constraint "group_type IS NULL OR (group_type::text = ANY (ARRAY['superset'::character varying::text, 'circuit'::character varying::text, 'emom'::character varying::text]))", name: "session_exercises_group_type_check"
  end

  create_table "session_sets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "actual_distance_m", precision: 8, scale: 2
    t.integer "actual_duration_s"
    t.decimal "actual_load_kg", precision: 8, scale: 3
    t.integer "actual_reps"
    t.decimal "actual_rpe", precision: 3, scale: 1
    t.datetime "client_updated_at"
    t.datetime "created_at", null: false
    t.decimal "e1rm_kg", precision: 8, scale: 3
    t.decimal "effective_load_kg", precision: 8, scale: 3
    t.boolean "is_warmup", default: false, null: false
    t.uuid "parent_set_id"
    t.decimal "planned_distance_m", precision: 8, scale: 2
    t.integer "planned_duration_s"
    t.boolean "planned_is_amrap", default: false, null: false
    t.decimal "planned_load_kg", precision: 8, scale: 3
    t.integer "planned_reps_max"
    t.integer "planned_reps_min"
    t.decimal "planned_rpe", precision: 3, scale: 1
    t.uuid "session_exercise_id", null: false
    t.integer "set_number", null: false
    t.string "status", default: "pending", null: false
    t.string "technique", default: "none", null: false
    t.datetime "updated_at", null: false
    t.decimal "velocity_mps", precision: 5, scale: 3
    t.decimal "volume_kg", precision: 10, scale: 3
    t.index ["parent_set_id"], name: "index_session_sets_on_parent_set_id"
    t.index ["session_exercise_id", "set_number"], name: "index_session_sets_on_exercise_and_number"
    t.index ["session_exercise_id"], name: "index_session_sets_on_session_exercise_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'done'::character varying::text, 'skipped'::character varying::text])", name: "session_sets_status_check"
    t.check_constraint "technique::text = ANY (ARRAY['none'::character varying::text, 'drop'::character varying::text, 'cluster'::character varying::text])", name: "session_sets_technique_check"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "name"
    t.text "notes"
    t.uuid "phase_id"
    t.date "session_date", null: false
    t.datetime "started_at"
    t.string "status", default: "planned", null: false
    t.datetime "updated_at", null: false
    t.uuid "workout_template_id"
    t.index ["client_id", "session_date"], name: "index_sessions_on_client_id_and_session_date"
    t.index ["client_id"], name: "index_sessions_on_client_id"
    t.index ["phase_id"], name: "index_sessions_on_phase_id"
    t.index ["workout_template_id"], name: "index_sessions_on_workout_template_id"
    t.check_constraint "status::text = ANY (ARRAY['planned'::character varying::text, 'in_progress'::character varying::text, 'completed'::character varying::text, 'skipped'::character varying::text])", name: "sessions_status_check"
  end

  create_table "template_exercises", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "block", null: false
    t.string "conditioning_method"
    t.datetime "created_at", null: false
    t.string "effort_mode", default: "rpe", null: false
    t.integer "emom_interval_s"
    t.integer "emom_total_s"
    t.string "energy_system"
    t.uuid "exercise_id", null: false
    t.string "group_label"
    t.integer "group_rounds"
    t.string "group_type"
    t.text "notes"
    t.integer "position", default: 0, null: false
    t.integer "rest_seconds"
    t.integer "target_hr_pct"
    t.string "tempo"
    t.datetime "updated_at", null: false
    t.uuid "workout_template_id", null: false
    t.index ["exercise_id"], name: "index_template_exercises_on_exercise_id"
    t.index ["workout_template_id", "block", "position"], name: "index_template_exercises_on_template_block_position"
    t.index ["workout_template_id"], name: "index_template_exercises_on_workout_template_id"
    t.check_constraint "block::text = ANY (ARRAY['movement_prep'::character varying::text, 'neural_prep'::character varying::text, 'power'::character varying::text, 'strength'::character varying::text, 'accessory'::character varying::text, 'aerobic'::character varying::text, 'cool_down'::character varying::text])", name: "template_exercises_block_check"
    t.check_constraint "effort_mode::text = ANY (ARRAY['rpe'::character varying::text, 'rir'::character varying::text])", name: "template_exercises_effort_mode_check"
    t.check_constraint "energy_system IS NULL OR (energy_system::text = ANY (ARRAY['aerobic'::character varying::text, 'glycolytic'::character varying::text, 'atp_pcr'::character varying::text]))", name: "template_exercises_energy_system_check"
    t.check_constraint "group_type IS NULL OR (group_type::text = ANY (ARRAY['superset'::character varying::text, 'circuit'::character varying::text, 'emom'::character varying::text]))", name: "template_exercises_group_type_check"
  end

  create_table "template_sets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "distance_m", precision: 8, scale: 2
    t.integer "duration_s"
    t.boolean "is_amrap", default: false, null: false
    t.decimal "load_kg", precision: 8, scale: 3
    t.decimal "load_pct_e1rm", precision: 5, scale: 2
    t.integer "reps_max"
    t.integer "reps_min"
    t.decimal "rpe_target", precision: 3, scale: 1
    t.integer "set_number", null: false
    t.uuid "template_exercise_id", null: false
    t.datetime "updated_at", null: false
    t.index ["template_exercise_id", "set_number"], name: "index_template_sets_on_template_exercise_id_and_set_number", unique: true
    t.index ["template_exercise_id"], name: "index_template_sets_on_template_exercise_id"
  end

  create_table "trainers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "accent_color"
    t.integer "assessment_cadence_days", default: 30, null: false
    t.string "business_name"
    t.datetime "created_at", null: false
    t.integer "e1rm_window_days", default: 42, null: false
    t.string "email_address", null: false
    t.string "logo_url"
    t.string "name"
    t.string "password_digest", null: false
    t.integer "report_cadence_days", default: 56, null: false
    t.string "timezone", default: "UTC", null: false
    t.string "unit_system", default: "lb", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email_address)::text)", name: "index_trainers_on_lower_email", unique: true
    t.check_constraint "unit_system::text = ANY (ARRAY['lb'::character varying::text, 'kg'::character varying::text])", name: "trainers_unit_system_check"
  end

  create_table "workout_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "block"
    t.uuid "client_id"
    t.datetime "created_at", null: false
    t.integer "day_number"
    t.text "description"
    t.boolean "is_block_template", default: false, null: false
    t.string "name", null: false
    t.uuid "phase_id"
    t.string "program_name"
    t.uuid "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.integer "week_number"
    t.index ["client_id"], name: "index_workout_templates_on_client_id"
    t.index ["phase_id"], name: "index_workout_templates_on_phase_id"
    t.index ["trainer_id", "client_id"], name: "index_workout_templates_on_trainer_id_and_client_id"
    t.index ["trainer_id"], name: "index_workout_templates_on_trainer_id"
    t.check_constraint "block IS NULL OR (block::text = ANY (ARRAY['movement_prep'::character varying::text, 'neural_prep'::character varying::text, 'power'::character varying::text, 'strength'::character varying::text, 'accessory'::character varying::text, 'aerobic'::character varying::text, 'cool_down'::character varying::text]))", name: "workout_templates_block_check"
  end

  add_foreign_key "auth_sessions", "trainers"
  add_foreign_key "block_presets", "phases"
  add_foreign_key "block_presets", "trainers"
  add_foreign_key "client_menu_exercises", "clients"
  add_foreign_key "client_menu_exercises", "exercises"
  add_foreign_key "client_pattern_benchmarks", "clients"
  add_foreign_key "client_pattern_benchmarks", "exercises"
  add_foreign_key "client_pattern_benchmarks", "main_patterns"
  add_foreign_key "client_presentations", "clients"
  add_foreign_key "client_presentations", "presentations"
  add_foreign_key "client_tracked_metrics", "clients"
  add_foreign_key "client_tracked_metrics", "metric_types"
  add_foreign_key "clients", "phases", column: "current_phase_id"
  add_foreign_key "clients", "trainers"
  add_foreign_key "exercise_muscle_groups", "exercises"
  add_foreign_key "exercise_muscle_groups", "muscle_groups"
  add_foreign_key "exercise_type_muscle_groups", "exercise_types"
  add_foreign_key "exercise_type_muscle_groups", "muscle_groups"
  add_foreign_key "exercise_types", "main_patterns"
  add_foreign_key "exercises", "exercise_types"
  add_foreign_key "exercises", "trainers"
  add_foreign_key "goals", "clients"
  add_foreign_key "goals", "main_patterns"
  add_foreign_key "goals", "metric_types"
  add_foreign_key "metric_entries", "clients"
  add_foreign_key "metric_entries", "metric_types"
  add_foreign_key "metric_types", "trainers"
  add_foreign_key "notes", "clients"
  add_foreign_key "phases", "trainers"
  add_foreign_key "presentations", "trainers"
  add_foreign_key "readiness_entries", "clients"
  add_foreign_key "readiness_entries", "sessions"
  add_foreign_key "reports", "clients"
  add_foreign_key "session_exercises", "exercises"
  add_foreign_key "session_exercises", "exercises", column: "planned_exercise_id"
  add_foreign_key "session_exercises", "sessions"
  add_foreign_key "session_sets", "session_exercises"
  add_foreign_key "session_sets", "session_sets", column: "parent_set_id"
  add_foreign_key "sessions", "clients"
  add_foreign_key "sessions", "phases"
  add_foreign_key "sessions", "workout_templates"
  add_foreign_key "template_exercises", "exercises"
  add_foreign_key "template_exercises", "workout_templates"
  add_foreign_key "template_sets", "template_exercises"
  add_foreign_key "workout_templates", "clients"
  add_foreign_key "workout_templates", "phases"
  add_foreign_key "workout_templates", "trainers"
end
