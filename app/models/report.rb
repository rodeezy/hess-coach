# Report cards arrive in phase 6. Publishing freezes a snapshot so the numbers
# never change after sending (RC-3).
class Report < ApplicationRecord
  belongs_to :client

  has_secure_token :share_token, length: 36

  validates :period_start, :period_end, presence: true

  scope :published, -> { where(status: "published") }
end
