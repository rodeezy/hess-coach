class HomeController < InertiaController
  def show
    clients = current_trainer.clients.active.includes(:current_phase, :trainer)

    render inertia: "Home", props: {
      counts: {
        clients:   clients.size,
        exercises: current_trainer.exercises.active.count
      },
      # Clients whose last assessment is older than the cadence (MT-6).
      assessmentsDue: clients.select(&:assessment_overdue?).map { |c|
        { id: c.id, name: c.full_name, lastAssessmentOn: c.last_assessment_on }
      },
      # Not seen in 10+ days (spec section 8, Home).
      notSeen: clients.filter_map { |c|
        days = c.days_since_last_session
        { id: c.id, name: c.full_name, days: days } if days.nil? || days >= 10
      }
    }
  end
end
