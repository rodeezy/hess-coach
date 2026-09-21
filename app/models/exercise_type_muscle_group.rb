class ExerciseTypeMuscleGroup < ApplicationRecord
  belongs_to :exercise_type
  belongs_to :muscle_group
end
