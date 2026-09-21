# Which metrics show on this client's dashboard and assessment screen (MT-4).
class ClientTrackedMetric < ApplicationRecord
  belongs_to :client
  belongs_to :metric_type

  scope :in_order, -> { order(:sort_order) }
end
