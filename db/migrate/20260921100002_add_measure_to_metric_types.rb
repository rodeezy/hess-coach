class AddMeasureToMetricTypes < ActiveRecord::Migration[8.1]
  def change
    # Mass and length metrics are stored canonically (kg, cm) and displayed in
    # the trainer's unit, the same rule loads follow (spec 2, 6.7). FFMI needs
    # kilograms and metres regardless of what Julian types. Everything else
    # (degrees, bpm, %, reps, score) is unit-agnostic and stays null.
    add_column :metric_types, :measure, :string
    add_check_constraint :metric_types,
      "measure IS NULL OR measure IN ('mass','length')", name: "metric_types_measure_check"
  end
end
