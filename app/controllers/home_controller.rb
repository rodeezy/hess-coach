class HomeController < InertiaController
  def show
    render inertia: "Home", props: {
      trainer: current_trainer.as_json(only: %i[id name business_name email_address unit_system]),
      counts: {
        clients:       current_trainer.clients.where(status: "active").count,
        exercises:     current_trainer.exercises.where(is_archived: false).count,
        muscleGroups:  MuscleGroup.count,
        mainPatterns:  MainPattern.count,
        exerciseTypes: ExerciseType.count
      }
    }
  end
end
