class MetricEntry < ApplicationRecord
  belongs_to :client
  belongs_to :metric_type

  blanks_to_nil :source, :note

  validates :measured_on, presence: true
  validate  :has_some_value

  scope :on_or_before, ->(date) { where(measured_on: ..date) }
  scope :chronological, -> { order(:measured_on, :created_at) }

  # Best-of-3 tests keep every attempt and save the best as the value (MT-8).
  def best_of(attempt_values)
    attempt_values.compact_blank.map(&:to_d).max
  end

  def two_sided? = metric_type.is_two_sided

  private

  def has_some_value
    return if value.present? || value_left.present? || value_right.present?

    errors.add(:base, "needs a value")
  end
end
