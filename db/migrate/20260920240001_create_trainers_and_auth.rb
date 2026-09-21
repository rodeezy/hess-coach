class CreateTrainersAndAuth < ActiveRecord::Migration[8.1]
  def change
    create_table :trainers, id: :uuid do |t|
      t.string  :email_address,           null: false
      t.string  :password_digest,         null: false
      t.string  :name
      t.string  :business_name
      t.string  :logo_url
      t.string  :accent_color
      t.string  :unit_system,             null: false, default: "lb"
      t.integer :e1rm_window_days,        null: false, default: 42
      t.integer :report_cadence_days,     null: false, default: 56
      t.integer :assessment_cadence_days, null: false, default: 30
      t.string  :timezone,                null: false, default: "UTC"

      t.timestamps
    end
    add_index :trainers, "lower(email_address)", unique: true, name: "index_trainers_on_lower_email"
    add_check_constraint :trainers, "unit_system IN ('lb','kg')", name: "trainers_unit_system_check"

    # Login sessions. Named auth_sessions so the domain keeps `sessions`
    # for training sessions, per the spec's data model.
    create_table :auth_sessions, id: :uuid do |t|
      t.references :trainer, null: false, foreign_key: true, type: :uuid
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
