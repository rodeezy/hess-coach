class MetricType < ApplicationRecord
  GROUPS = %w[biometric performance movement].freeze

  belongs_to :trainer, optional: true # null = built-in seeded type
  has_many :metric_entries, dependent: :restrict_with_error
  has_many :client_tracked_metrics, dependent: :destroy

  validates :name, :group, presence: true
  validates :group, inclusion: { in: GROUPS }
  validates :direction, inclusion: { in: %w[up down neutral] }

  scope :built_in,  -> { where(trainer_id: nil) }
  scope :in_order,  -> { order(:group, :sort_order, :name) }
  scope :for_trainer, ->(trainer) { where(trainer_id: [nil, trainer.id]) }

  def unit_label(unit_system) = Units.unit_label(measure: measure, unit_system: unit_system, fallback: unit)

  # FFMI is derived from body fat plus weight and is never typed in (MT-5).
  def enterable? = !is_computed
end
