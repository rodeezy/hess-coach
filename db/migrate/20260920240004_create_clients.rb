class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients, id: :uuid do |t|
      t.references :trainer,        null: false, foreign_key: true, type: :uuid
      t.string     :first_name,     null: false
      t.string     :last_name
      t.string     :email
      t.string     :phone
      t.date       :date_of_birth
      t.string     :sex
      t.decimal    :height_cm,      precision: 6, scale: 2
      t.date       :start_date
      t.string     :status,         null: false, default: "active"
      t.references :current_phase,  null: true, foreign_key: { to_table: :phases }, type: :uuid
      t.date       :phase_started_on
      t.boolean    :uses_power_block, null: false, default: false
      t.boolean    :uses_vbt,       null: false, default: false
      t.text       :intake_notes
      t.string     :disc_type
      t.integer    :max_hr
      t.integer    :report_cadence_days
      t.timestamps
    end
    add_index :clients, %i[trainer_id status]
    add_check_constraint :clients, "status IN ('active','archived')", name: "clients_status_check"
    add_check_constraint :clients, "disc_type IS NULL OR disc_type IN ('D','i','S','C')",
      name: "clients_disc_type_check"

    # Which metrics show for this client. All seeded metrics start off
    # except body weight (spec MT-4).
    create_table :client_tracked_metrics, id: :uuid do |t|
      t.references :client,      null: false, foreign_key: true, type: :uuid
      t.references :metric_type, null: false, foreign_key: true, type: :uuid
      t.integer    :sort_order,  null: false, default: 0
      t.timestamps
    end
    add_index :client_tracked_metrics, %i[client_id metric_type_id],
      unique: true, name: "index_ctm_on_client_and_metric_type"

    # The lift that defines each pattern's e1RM for this client. History rows are
    # kept so a benchmark change starts a new trend line (spec 6.2).
    create_table :client_pattern_benchmarks, id: :uuid do |t|
      t.references :client,         null: false, foreign_key: true, type: :uuid
      t.references :main_pattern,   null: false, foreign_key: true, type: :uuid
      t.references :exercise,       null: false, foreign_key: true, type: :uuid
      t.date       :effective_from, null: false
      t.timestamps
    end
    add_index :client_pattern_benchmarks, %i[client_id main_pattern_id effective_from],
      name: "index_cpb_on_client_pattern_effective"

    # Active when resolved_on is null; history kept so a report can show a
    # finding that cleared (spec 5).
    create_table :client_presentations, id: :uuid do |t|
      t.references :client,       null: false, foreign_key: true, type: :uuid
      t.references :presentation, null: false, foreign_key: true, type: :uuid
      t.date       :noted_on,     null: false
      t.date       :resolved_on
      t.text       :note
      t.timestamps
    end
    add_index :client_presentations, %i[client_id presentation_id resolved_on],
      name: "index_cp_on_client_presentation_resolved"

    create_table :client_menu_exercises, id: :uuid do |t|
      t.references :client,   null: false, foreign_key: true, type: :uuid
      t.references :exercise, null: false, foreign_key: true, type: :uuid
      t.date       :added_on, null: false
      t.timestamps
    end
    add_index :client_menu_exercises, %i[client_id exercise_id],
      unique: true, name: "index_cme_on_client_and_exercise"
  end
end
