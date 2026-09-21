class ExerciseType < ApplicationRecord
  belongs_to :main_pattern, optional: true
  has_many :exercise_type_muscle_groups, dependent: :destroy
  has_many :muscle_groups, through: :exercise_type_muscle_groups
  has_many :exercises, dependent: :restrict_with_error
end
