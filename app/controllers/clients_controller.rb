class ClientsController < InertiaController
  before_action :set_client, only: %i[show edit update archive unarchive change_phase]

  # Sorted by last session date, showing days since and next report due (CL-2).
  def index
    clients = current_trainer.clients.includes(:current_phase)
    clients = clients.where(status: params[:status] == "archived" ? "archived" : "active")
    if params[:q].present?
      clients = clients.where("first_name ILIKE :q OR last_name ILIKE :q", q: "%#{params[:q]}%")
    end

    rows = clients.to_a.sort_by { |c| c.last_session_date || Date.new(1900) }.reverse

    render inertia: "Clients/Index", props: {
      filters: params.permit(:q, :status).to_h,
      clients: rows.map { |c| summary(c) },
      counts: {
        active:   current_trainer.clients.active.count,
        archived: current_trainer.clients.archived.count
      }
    }
  end

  def new
    render inertia: "Clients/Form", props: { client: blank_client, phases: phase_options }
  end

  def create
    client = current_trainer.clients.new(client_params)
    client.status ||= "active"

    if client.save
      apply_default_tracked_metrics(client)
      redirect_to client_path(client), notice: "Client added."
    else
      redirect_to new_client_path, inertia: { errors: client.errors.to_hash(true) }
    end
  end

  def edit
    render inertia: "Clients/Form", props: {
      client: serialize_for_form(@client), phases: phase_options
    }
  end

  def update
    if @client.update(client_params)
      redirect_to client_path(@client), notice: "Client updated."
    else
      redirect_to edit_client_path(@client), inertia: { errors: @client.errors.to_hash(true) }
    end
  end

  def show
    render inertia: "Clients/Show", props: {
      client: detail(@client),
      tab: params[:tab].presence || "overview",
      pinnedNotes: @client.notes.pinned.recent.map { |n| note_json(n) },
      recentNotes: @client.notes.recent.limit(5).map { |n| note_json(n) },
      trackedMetrics: tracked_metric_tiles(@client),
      phases: phase_options
    }
  end

  def archive
    @client.archive!
    redirect_to clients_path, notice: "#{@client.full_name} archived. Their data is kept."
  end

  def unarchive
    @client.unarchive!
    redirect_to client_path(@client), notice: "#{@client.full_name} is active again."
  end

  # Manual, one tap, with a date. The app never suggests this (CL-6).
  def change_phase
    @client.update!(
      current_phase_id: params[:phase_id].presence,
      phase_started_on: params[:started_on].presence || Date.current
    )
    redirect_to client_path(@client), notice: "Phase updated."
  end

  private

  def set_client = @client = current_trainer.clients.find(params[:id])

  def client_params
    params.permit(:first_name, :last_name, :email, :phone, :date_of_birth, :sex,
                  :height_cm, :start_date, :intake_notes, :disc_type, :max_hr,
                  :uses_power_block, :uses_vbt, :report_cadence_days,
                  :current_phase_id, :phase_started_on)
  end

  def blank_client
    { first_name: "", last_name: "", email: "", phone: "", date_of_birth: nil, sex: nil,
      height_cm: nil, start_date: Date.current, intake_notes: "", disc_type: nil,
      max_hr: nil, uses_power_block: false, uses_vbt: false, report_cadence_days: nil,
      current_phase_id: nil, phase_started_on: nil }
  end

  def serialize_for_form(client)
    client.as_json(only: %i[id first_name last_name email phone date_of_birth sex
                            height_cm start_date intake_notes disc_type max_hr
                            uses_power_block uses_vbt report_cadence_days
                            current_phase_id phase_started_on])
  end

  def phase_options
    current_trainer.phases.where(is_archived: false).order(:sort_order).map do |p|
      { id: p.id, name: p.name, sweetMin: p.sweet_min_weeks, sweetMax: p.sweet_max_weeks }
    end
  end

  # All seeded metrics start switched off except body weight (MT-4).
  def apply_default_tracked_metrics(client)
    Seeds::MetricTypes::DEFAULT_TRACKED.each_with_index do |key, i|
      type = MetricType.find_by(trainer_id: nil, key: key)
      next if type.nil?

      client.tracked_metrics.create!(metric_type: type, sort_order: i)
    end
  end

  def summary(client)
    {
      id: client.id, name: client.full_name, status: client.status,
      daysSinceLastSession: client.days_since_last_session,
      lastSessionOn: client.last_session_date,
      nextReportDueOn: client.next_report_due_on,
      assessmentOverdue: client.assessment_overdue?,
      phase: client.current_phase&.name,
      weeksInPhase: client.weeks_in_phase
    }
  end

  def detail(client)
    phase = client.current_phase
    {
      id: client.id, firstName: client.first_name, lastName: client.last_name,
      name: client.full_name, email: client.email, phone: client.phone,
      status: client.status, startDate: client.start_date, sex: client.sex,
      heightCm: client.height_cm, age: client.age_on, discType: client.disc_type,
      usesPowerBlock: client.uses_power_block, usesVbt: client.uses_vbt,
      intakeNotes: client.intake_notes,
      daysSinceLastSession: client.days_since_last_session,
      lastAssessmentOn: client.last_assessment_on,
      assessmentOverdue: client.assessment_overdue?,
      nextReportDueOn: client.next_report_due_on,
      phase: phase && {
        id: phase.id, name: phase.name,
        startedOn: client.phase_started_on,
        weeks: client.weeks_in_phase,
        sweetMin: phase.sweet_min_weeks, sweetMax: phase.sweet_max_weeks
      }
    }
  end

  def note_json(note)
    { id: note.id, body: note.body, tag: note.tag,
      isPinned: note.is_pinned, notedAt: note.noted_at }
  end

  def tracked_metric_tiles(client)
    MetricPresenter.new(client: client, unit_system: current_trainer.unit_system).tiles
  end
end
