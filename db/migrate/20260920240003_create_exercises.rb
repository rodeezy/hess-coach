class CreateExercises < ActiveRecord::Migration[8.1]
  def change
    create_table :exercises, id: :uuid do |t|
      t.references :trainer,       null: false, foreign_key: true, type: :uuid
      t.string     :name,          null: false
      t.references :exercise_type, null: false, foreign_key: true, type: :uuid
      # Sheet order is progression order (Hand Elevated Pushups -> Pushup ->
      # Weighted Pushup). The swap panel in the logger relies on it (spec EX-2, SL-4).
      t.integer :sort_order,       null: false, default: 0
      t.string  :video_url
      t.text    :instructions
      t.boolean :needs_video,      null: false, default: false
      t.boolean :on_menu,          null: false, default: false
      t.string  :prescription,     null: false, default: "reps"
      t.boolean :is_unilateral,    null: false, default: false
      t.string  :load_type,        null: false, default: "external"
      t.integer :implement_count,  null: false, default: 1
      t.boolean :e1rm_eligible,    null: false, default: false
      t.boolean :is_archived,      null: false, default: false
      t.timestamps
    end
    # Jefferson Curl and Shinbox Getups legitimately appear under two types (spec 5).
    add_index :exercises, "trainer_id, lower(name), exercise_type_id",
      unique: true, name: "index_exercises_on_trainer_lower_name_type"
    add_index :exercises, %i[exercise_type_id sort_order]
    add_check_constraint :exercises,
      "prescription IN ('reps','time','distance')", name: "exercises_prescription_check"
    add_check_constraint :exercises,
      "load_type IN ('external','bodyweight','bodyweight_plus','assisted','none')",
      name: "exercises_load_type_check"
    add_check_constraint :exercises, "implement_count > 0", name: "exercises_implement_count_check"

    # Analytics read these at query time, so edits apply to history too (spec EX-6).
    create_table :exercise_muscle_groups, id: :uuid do |t|
      t.references :exercise,     null: false, foreign_key: true, type: :uuid
      t.references :muscle_group, null: false, foreign_key: true, type: :uuid
      t.string     :role,         null: false
      t.timestamps
    end
    add_index :exercise_muscle_groups, %i[exercise_id muscle_group_id],
      unique: true, name: "index_emg_on_exercise_and_group"
    add_check_constraint :exercise_muscle_groups,
      "role IN ('primary','secondary')", name: "emg_role_check"
  end
end
