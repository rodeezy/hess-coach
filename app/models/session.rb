# A dated training session for one client. Logging arrives in phase 4; this
# exists now because the client list reports days since the last session (CL-2).
# Note: login sessions are AuthSession. This is the domain's Session, as the
# spec's data model names it.
class Session < ApplicationRecord
  STATUSES = %w[planned in_progress completed skipped].freeze

  belongs_to :client
  belongs_to :workout_template, optional: true
  belongs_to :phase, optional: true

  has_many :session_exercises, dependent: :destroy
  has_many :readiness_entries, dependent: :nullify

  validates :session_date, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :completed, -> { where(status: "completed") }
  scope :on_or_before, ->(date) { where(session_date: ..date) }
end
