class ExercisesController < InertiaController
  def index
    exercises = current_trainer.exercises.active
      .includes(:exercise_type, exercise_muscle_groups: :muscle_group)

    exercises = exercises.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
    exercises = exercises.where(exercise_type_id: params[:type_id]) if params[:type_id].present?
    exercises = exercises.where(needs_video: true) if params[:needs_video] == "1"
    if params[:muscle_group_id].present?
      exercises = exercises.where(
        id: ExerciseMuscleGroup.where(muscle_group_id: params[:muscle_group_id]).select(:exercise_id)
      )
    end

    types = ExerciseType.order(:sort_order).to_a
    grouped = exercises.in_order.group_by(&:exercise_type_id)

    render inertia: "Library", props: {
      filters: params.permit(:q, :type_id, :needs_video, :muscle_group_id).to_h,
      types: types.map { |t|
        rows = grouped[t.id] || []
        {
          id: t.id, name: t.name, group: t.group, bodyArea: t.body_area,
          defaultBlock: t.default_block, prescription: t.default_prescription,
          exercises: rows.map { |e| serialize(e) }
        }
      }.select { |t| t[:exercises].any? },
      muscleGroups: MuscleGroup.in_order.map { |m| { id: m.id, name: m.name } },
      allTypes: types.map { |t| { id: t.id, name: t.name } },
      totals: {
        exercises:  current_trainer.exercises.active.count,
        needsVideo: current_trainer.exercises.active.where(needs_video: true).count,
        e1rm:       current_trainer.exercises.active.where(e1rm_eligible: true).count
      }
    }
  end

  private

  def serialize(exercise)
    {
      id: exercise.id,
      name: exercise.name,
      videoUrl: exercise.video_url,
      instructions: exercise.instructions,
      needsVideo: exercise.needs_video,
      prescription: exercise.prescription,
      e1rmEligible: exercise.e1rm_eligible,
      isUnilateral: exercise.is_unilateral,
      loadType: exercise.load_type,
      implementCount: exercise.implement_count,
      muscles: exercise.exercise_muscle_groups
        .sort_by { |m| m.role == "primary" ? 0 : 1 }
        .map { |m| { name: m.muscle_group.name, role: m.role } }
    }
  end
end
