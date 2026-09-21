class CreateTracking < ActiveRecord::Migration[8.1]
  def change
    create_table :metric_entries, id: :uuid do |t|
      t.references :client,      null: false, foreign_key: true, type: :uuid
      t.references :metric_type, null: false, foreign_key: true, type: :uuid
      t.decimal    :value,       precision: 10, scale: 3
      # Two-sided types record both in one entry and chart as two lines (spec MT-2).
      t.decimal    :value_left,  precision: 10, scale: 3
      t.decimal    :value_right, precision: 10, scale: 3
      # Raw tries for best-of-3 tests such as grip strength (spec MT-8).
      t.jsonb      :attempts
      # e.g. "DEXA" (spec MT-9).
      t.string     :source
      t.date       :measured_on, null: false
      t.text       :note
      t.timestamps
    end
    add_index :metric_entries, %i[client_id metric_type_id measured_on],
      name: "index_metric_entries_on_client_type_date"

    create_table :goals, id: :uuid do |t|
      t.references :client,       null: false, foreign_key: true, type: :uuid
      t.string     :title,        null: false
      t.text       :description
      t.string     :category,     null: false, default: "performance"
      t.string     :kind,         null: false, default: "qualitative"
      t.references :metric_type,  null: true, foreign_key: true, type: :uuid
      t.string     :metric_side
      t.references :main_pattern, null: true, foreign_key: true, type: :uuid
      t.decimal    :start_value,  precision: 10, scale: 3
      t.decimal    :target_value, precision: 10, scale: 3
      t.date       :start_date
      t.date       :target_date
      t.string     :status,       null: false, default: "active"
      t.timestamps
    end
    add_index :goals, %i[client_id status]
    add_check_constraint :goals,
      "category IN ('performance','body_comp','movement','lifestyle')", name: "goals_category_check"
    add_check_constraint :goals,
      "kind IN ('metric','pattern_e1rm','qualitative')", name: "goals_kind_check"
    add_check_constraint :goals,
      "status IN ('active','achieved','paused','dropped')", name: "goals_status_check"
    add_check_constraint :goals,
      "metric_side IS NULL OR metric_side IN ('left','right')", name: "goals_metric_side_check"

    create_table :notes, id: :uuid do |t|
      t.references :client,    null: false, foreign_key: true, type: :uuid
      t.text       :body,      null: false
      t.string     :tag
      t.boolean    :is_pinned, null: false, default: false
      t.datetime   :noted_at,  null: false
      t.timestamps
    end
    add_index :notes, %i[client_id is_pinned noted_at]
    add_check_constraint :notes,
      "tag IS NULL OR tag IN ('injury','preference','lifestyle','program','general')",
      name: "notes_tag_check"

    create_table :reports, id: :uuid do |t|
      t.references :client,         null: false, foreign_key: true, type: :uuid
      t.date       :period_start,   null: false
      t.date       :period_end,     null: false
      t.string     :status,         null: false, default: "draft"
      t.text       :coach_summary
      t.text       :next_focus
      t.jsonb      :goal_comments
      t.jsonb      :hidden_sections
      # Frozen at publish: the public page renders only from this (spec RC-3).
      t.jsonb      :snapshot
      t.string     :share_token,    null: false
      t.datetime   :published_at
      t.datetime   :sent_at
      t.timestamps
    end
    add_index :reports, :share_token, unique: true
    add_index :reports, %i[client_id period_end]
    add_check_constraint :reports, "status IN ('draft','published')", name: "reports_status_check"
    add_check_constraint :reports, "period_end >= period_start", name: "reports_period_check"
  end
end
