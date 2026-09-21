# Timestamped client notes with optional tags (NT-1).
class Note < ApplicationRecord
  TAGS = %w[injury preference lifestyle program general].freeze

  belongs_to :client

  blanks_to_nil :tag

  validates :body, presence: true
  validates :tag, inclusion: { in: TAGS }, allow_nil: true

  before_validation { self.noted_at ||= Time.current }

  scope :pinned, -> { where(is_pinned: true) }
  scope :recent, -> { order(is_pinned: :desc, noted_at: :desc) }
  scope :search, ->(q) { q.present? ? where("body ILIKE ?", "%#{q}%") : all }

  # Injury and limitation notes surface as a banner on the logger (NT-2).
  scope :for_logger_banner, -> { pinned.where(tag: %w[injury lifestyle]) }
end
