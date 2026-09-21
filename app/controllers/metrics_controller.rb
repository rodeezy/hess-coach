class MetricsController < InertiaController
  before_action :set_client

  def index
    presenter = MetricPresenter.new(client: @client, unit_system: unit_system)

    render inertia: "Clients/Metrics", props: {
      client: { id: @client.id, name: @client.full_name, heightCm: @client.height_cm },
      tiles: presenter.tiles,
      available: available_metric_types,
      tracked: @client.tracked_metrics.in_order.pluck(:metric_type_id),
      dexaKeys: Seeds::MetricTypes::DEXA_KEYS
    }
  end

  # Which metrics matter for this client's goal (MT-4).
  def update_tracked
    ids = Array(params[:metric_type_ids]).compact_blank

    ActiveRecord::Base.transaction do
      @client.tracked_metrics.where.not(metric_type_id: ids).destroy_all
      ids.each_with_index do |id, i|
        row = @client.tracked_metrics.find_or_initialize_by(metric_type_id: id)
        row.sort_order = i
        row.save!
      end
    end

    redirect_back fallback_location: client_metrics_path(@client), notice: "Tracked metrics updated."
  end

  private

  def set_client   = @client = current_trainer.clients.find(params[:client_id])
  def unit_system  = current_trainer.unit_system

  def available_metric_types
    MetricType.for_trainer(current_trainer).in_order.map do |t|
      { id: t.id, key: t.key, name: t.name, group: t.group,
        unit: t.unit_label(unit_system), twoSided: t.is_two_sided,
        bestOfThree: t.is_best_of_three, computed: t.is_computed,
        decimals: t.decimals, custom: t.trainer_id.present? }
    end
  end
end
