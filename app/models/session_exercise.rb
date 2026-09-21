class SessionExercise < ApplicationRecord
  belongs_to :session
  belongs_to :exercise
  belongs_to :planned_exercise, class_name: "Exercise", optional: true

  has_many :session_sets, dependent: :destroy
end
