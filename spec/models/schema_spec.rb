require "rails_helper"

# The spec's data model is a requirement, not a suggestion (section 2), so the
# 27 tables it names are asserted directly.
RSpec.describe "Schema" do
  SPEC_TABLES = %w[
    trainers clients main_patterns exercise_types muscle_groups
    exercise_type_muscle_groups exercises exercise_muscle_groups block_presets
    workout_templates template_exercises template_sets sessions session_exercises
    session_sets readiness_entries metric_types metric_entries
    client_tracked_metrics client_pattern_benchmarks goals notes reports
    presentations client_presentations client_menu_exercises phases
  ].freeze

  it "defines all 27 tables from spec section 5" do
    expect(SPEC_TABLES.size).to eq(27)
    missing = SPEC_TABLES.reject { |t| ActiveRecord::Base.connection.table_exists?(t) }
    expect(missing).to be_empty
  end

  it "uses uuid primary keys everywhere" do
    non_uuid = SPEC_TABLES.reject do |table|
      ActiveRecord::Base.connection.columns(table).find { |c| c.name == "id" }&.sql_type == "uuid"
    end
    expect(non_uuid).to be_empty
  end
end
