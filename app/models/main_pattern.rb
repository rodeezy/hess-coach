class MainPattern < ApplicationRecord
  has_many :exercise_types, dependent: :restrict_with_error
  scope :in_order, -> { order(:sort_order) }
end
