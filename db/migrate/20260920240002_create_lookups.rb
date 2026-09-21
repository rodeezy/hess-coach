class CreateLookups < ActiveRecord::Migration[8.1]
  SESSION_BLOCKS = %w[movement_prep neural_prep power strength accessory aerobic cool_down].freeze

  def change
    # Six main patterns every e1RM trend line rolls up to (spec 5).
    create_table :main_patterns, id: :uuid do |t|
      t.string  :key,        null: false
      t.string  :name,       null: false
      t.integer :sort_order, null: false, default: 0
      t.timestamps
    end
    add_index :main_patterns, :key, unique: true

    # Sixteen muscle groups: the grain weekly set counts are reported at (spec 7).
    create_table :muscle_groups, id: :uuid do |t|
      t.string  :key,        null: false
      t.string  :name,       null: false
      t.string  :region,     null: false
      t.integer :sort_order, null: false, default: 0
      t.timestamps
    end
    add_index :muscle_groups, :key, unique: true
    add_check_constraint :muscle_groups, "region IN ('upper','lower','core')", name: "muscle_groups_region_check"

    # Seeded from Julian's Exercise Type column. Carries the defaults that make
    # categorisation automatic (spec 7).
    create_table :exercise_types, id: :uuid do |t|
      t.string     :key,                  null: false
      t.string     :name,                 null: false
      t.string     :group,                null: false
      t.references :main_pattern,         null: true, foreign_key: true, type: :uuid
      t.string     :default_block,        null: false
      t.string     :default_prescription, null: false, default: "reps"
      t.string     :body_area
      t.string     :menu_category
      t.integer    :sort_order,           null: false, default: 0
      t.timestamps
    end
    add_index :exercise_types, :key, unique: true
    add_check_constraint :exercise_types,
      "default_block IN (#{SESSION_BLOCKS.map { |b| "'#{b}'" }.join(',')})",
      name: "exercise_types_default_block_check"
    add_check_constraint :exercise_types,
      "default_prescription IN ('reps','time','distance')",
      name: "exercise_types_default_prescription_check"

    # Muscle defaults per type, copied onto each exercise at import (spec 5).
    create_table :exercise_type_muscle_groups, id: :uuid do |t|
      t.references :exercise_type, null: false, foreign_key: true, type: :uuid
      t.references :muscle_group,  null: false, foreign_key: true, type: :uuid
      t.string     :role,          null: false
      t.timestamps
    end
    add_index :exercise_type_muscle_groups, %i[exercise_type_id muscle_group_id],
      unique: true, name: "index_etmg_on_type_and_group"
    add_check_constraint :exercise_type_muscle_groups,
      "role IN ('primary','secondary')", name: "etmg_role_check"

    # Phases are rows, not code: Julian renames and edits them in Settings (spec 3).
    create_table :phases, id: :uuid do |t|
      t.references :trainer,           null: false, foreign_key: true, type: :uuid
      t.string     :name,              null: false
      t.integer    :typical_min_weeks
      t.integer    :typical_max_weeks
      t.integer    :sweet_min_weeks
      t.integer    :sweet_max_weeks
      t.integer    :sort_order,        null: false, default: 0
      t.boolean    :is_archived,       null: false, default: false
      t.timestamps
    end
    add_index :phases, %i[trainer_id sort_order]

    # trainer_id null = built-in seeded type (spec 5).
    create_table :metric_types, id: :uuid do |t|
      t.references :trainer,       null: true, foreign_key: true, type: :uuid
      t.string     :key,           null: false
      t.string     :name,          null: false
      t.string     :group,         null: false
      t.string     :unit
      t.string     :direction,     null: false, default: "neutral"
      t.integer    :decimals,      null: false, default: 1
      t.boolean    :is_two_sided,  null: false, default: false
      t.boolean    :is_computed,   null: false, default: false
      t.boolean    :is_best_of_three, null: false, default: false
      t.timestamps
    end
    add_index :metric_types, %i[trainer_id key], unique: true
    add_check_constraint :metric_types,
      "\"group\" IN ('biometric','performance','movement')", name: "metric_types_group_check"
    add_check_constraint :metric_types,
      "direction IN ('up','down','neutral')", name: "metric_types_direction_check"

    # Copied per trainer so the guidance text stays editable (spec 5).
    create_table :presentations, id: :uuid do |t|
      t.references :trainer,                null: false, foreign_key: true, type: :uuid
      t.string     :key,                    null: false
      t.string     :name,                   null: false
      t.text       :movement_prep_focus
      t.text       :exercise_selection_rule
      t.integer    :sort_order,             null: false, default: 0
      t.timestamps
    end
    add_index :presentations, %i[trainer_id key], unique: true
  end
end
