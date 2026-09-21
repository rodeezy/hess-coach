# Goals arrive properly in phase 5 with progress and pace (GL-1 to 4).
class Goal < ApplicationRecord
  CATEGORIES = %w[performance body_comp movement lifestyle].freeze
  KINDS      = %w[metric pattern_e1rm qualitative].freeze
  STATUSES   = %w[active achieved paused dropped].freeze

  belongs_to :client
  belongs_to :metric_type, optional: true
  belongs_to :main_pattern, optional: true

  blanks_to_nil :metric_side

  validates :title, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
end
