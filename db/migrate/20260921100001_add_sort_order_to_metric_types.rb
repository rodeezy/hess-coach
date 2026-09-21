class AddSortOrderToMetricTypes < ActiveRecord::Migration[8.1]
  def change
    # Assessment mode lists tracked metrics in group order (MT-6), and the
    # picker needs a stable order within each group.
    add_column :metric_types, :sort_order, :integer, null: false, default: 0
    add_index :metric_types, %i[group sort_order]
  end
end
