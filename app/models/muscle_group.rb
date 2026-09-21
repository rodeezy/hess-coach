class MuscleGroup < ApplicationRecord
  has_many :exercise_muscle_groups, dependent: :restrict_with_error
  scope :in_order, -> { order(:sort_order) }
end
