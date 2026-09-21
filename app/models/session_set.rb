# The analytics fact table. e1RM, effective load and tonnage are computed on
# write in phase 4 (spec 6.1, 6.3).
class SessionSet < ApplicationRecord
  belongs_to :session_exercise
  belongs_to :parent_set, class_name: "SessionSet", optional: true

  has_many :drops, class_name: "SessionSet", foreign_key: :parent_set_id, dependent: :destroy
end
