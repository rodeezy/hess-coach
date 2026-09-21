class MetricEntriesController < InertiaController
  before_action :set_client
  before_action :set_entry, only: %i[update destroy]

  def create
    entry = @client.metric_entries.new(entry_attributes)

    if entry.save
      redirect_back fallback_location: client_metrics_path(@client), notice: "Recorded."
    else
      redirect_back fallback_location: client_metrics_path(@client),
        inertia: { errors: entry.errors.to_hash(true) }
    end
  end

  def update
    if @entry.update(entry_attributes)
      redirect_back fallback_location: client_metrics_path(@client)
    else
      redirect_back fallback_location: client_metrics_path(@client),
        inertia: { errors: @entry.errors.to_hash(true) }
    end
  end

  def destroy
    @entry.destroy
    redirect_back fallback_location: client_metrics_path(@client), notice: "Entry deleted."
  end

  private

  def set_client = @client = current_trainer.clients.find(params[:client_id])
  def set_entry  = @entry = @client.metric_entries.find(params[:id])

  # Values arrive in the trainer's display unit and are stored canonically.
  def entry_attributes
    type = MetricType.for_trainer(current_trainer).find(params[:metric_type_id])
    attempts = Array(params[:attempts]).compact_blank
    attempts_right = Array(params[:attempts_right]).compact_blank

    value       = params[:value]
    value_left  = params[:value_left]
    value_right = params[:value_right]

    # Best of 3 per hand: the best attempt becomes the value (MT-8).
    if type.is_best_of_three
      if type.is_two_sided
        value_left  = attempts.map(&:to_d).max       if attempts.any?
        value_right = attempts_right.map(&:to_d).max if attempts_right.any?
      elsif attempts.any?
        value = attempts.map(&:to_d).max
      end
    end

    {
      metric_type: type,
      measured_on: params[:measured_on].presence || Date.current,
      note: params[:note],
      source: params[:source],
      attempts: ({ left: attempts, right: attempts_right }.compact_blank.presence if attempts.any? || attempts_right.any?),
      value:       canonical(value, type),
      value_left:  canonical(value_left, type),
      value_right: canonical(value_right, type)
    }
  end

  def canonical(value, type)
    Units.to_canonical(value, measure: type.measure, unit_system: current_trainer.unit_system)
  end
end
