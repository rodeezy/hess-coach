# Assessment mode: one screen listing the client's tracked metrics in group
# order for a monthly retest, each showing its last value beside the input
# (MT-6). Saved in one call so a whole assessment is a single action.
class AssessmentsController < InertiaController
  before_action :set_client

  def show
    presenter = MetricPresenter.new(client: @client, unit_system: current_trainer.unit_system)
    tiles = presenter.tiles.reject { |t| t[:computed] }

    render inertia: "Clients/Assessment", props: {
      client: {
        id: @client.id, name: @client.full_name,
        lastAssessmentOn: @client.last_assessment_on,
        assessmentOverdue: @client.assessment_overdue?
      },
      today: Date.current,
      dexaKeys: Seeds::MetricTypes::DEXA_KEYS,
      groups: MetricType::GROUPS.filter_map { |group|
        rows = tiles.select { |t| t[:group] == group }
        next if rows.empty?

        { group: group, metrics: rows.map { |t| row_for(t) } }
      }
    }
  end

  # Batch save: one assessment, one call (spec section 8, Metrics).
  def create
    measured_on = params[:measured_on].presence || Date.current
    source = params[:source].presence
    saved = 0

    ActiveRecord::Base.transaction do
      Array(params[:entries]).each do |raw|
        entry = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw
        next if blank_entry?(entry)

        type = MetricType.for_trainer(current_trainer).find(entry["metric_type_id"])
        attributes = build_attributes(entry, type, measured_on, source)

        record = @client.metric_entries.find_or_initialize_by(
          metric_type_id: type.id, measured_on: measured_on
        )
        record.assign_attributes(attributes)
        record.save!
        saved += 1
      end
    end

    redirect_to client_path(@client, tab: "metrics"),
      notice: saved.zero? ? "Nothing to save." : "Assessment saved: #{saved} #{'metric'.pluralize(saved)}."
  end

  private

  def set_client = @client = current_trainer.clients.find(params[:client_id])

  def row_for(tile)
    last = tile[:points].last
    {
      id: tile[:id], key: tile[:key], name: tile[:name], unit: tile[:unit],
      twoSided: tile[:twoSided], bestOfThree: tile[:bestOfThree],
      decimals: tile[:decimals],
      last: last && { date: last[:date], value: last[:value],
                      left: last[:left], right: last[:right] }
    }
  end

  def blank_entry?(entry)
    %w[value value_left value_right].all? { |k| entry[k].blank? } &&
      Array(entry["attempts"]).compact_blank.empty? &&
      Array(entry["attempts_right"]).compact_blank.empty?
  end

  def build_attributes(entry, type, measured_on, source)
    attempts       = Array(entry["attempts"]).compact_blank
    attempts_right = Array(entry["attempts_right"]).compact_blank

    value       = entry["value"]
    value_left  = entry["value_left"]
    value_right = entry["value_right"]

    if type.is_best_of_three
      if type.is_two_sided
        value_left  = attempts.map(&:to_d).max       if attempts.any?
        value_right = attempts_right.map(&:to_d).max if attempts_right.any?
      elsif attempts.any?
        value = attempts.map(&:to_d).max
      end
    end

    {
      measured_on: measured_on,
      note: entry["note"],
      source: Seeds::MetricTypes::DEXA_KEYS.include?(type.key) ? source : nil,
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
