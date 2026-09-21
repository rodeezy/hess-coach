# Turns a client's metric entries into display-ready tiles and chart series.
# Everything is converted from canonical storage into the trainer's unit here,
# at the edge (spec section 2).
class MetricPresenter
  def initialize(client:, unit_system:)
    @client = client
    @unit_system = unit_system
  end

  def tiles
    tracked.map { |type| tile(type) }
  end

  def tile(type)
    points = type.is_computed ? computed_points(type) : entry_points(type)
    last = points.last
    prev = points[-2]

    {
      id: type.id,
      key: type.key,
      name: type.name,
      group: type.group,
      unit: type.unit_label(@unit_system),
      direction: type.direction,
      decimals: type.decimals,
      twoSided: type.is_two_sided,
      bestOfThree: type.is_best_of_three,
      computed: type.is_computed,
      points: points,
      latest: last,
      change: change_between(prev, last)
    }
  end

  # FFMI is derived, never typed in (MT-5, spec 6.8).
  def computed_points(type)
    return [] unless type.key == "ffmi"
    return [] if @client.height_m.blank?

    Ffmi.series(
      body_fats: raw_pairs("body_fat"),
      weights:   raw_pairs("body_weight"),
      height_m:  @client.height_m
    ).map do |point|
      { date: point.measured_on, value: round_to(point.normalized, type.decimals),
        left: nil, right: nil, note: nil, source: nil, id: nil }
    end
  end

  private

  def tracked
    @client.tracked_metrics.in_order.includes(:metric_type).map(&:metric_type)
  end

  def entries_for(type)
    @client.metric_entries.where(metric_type_id: type.id).chronological
  end

  # Canonical values straight out of the database, for the FFMI maths.
  def raw_pairs(key)
    type = MetricType.find_by(key: key)
    return [] if type.nil?

    entries_for(type).filter_map { |e| [e.measured_on, e.value] if e.value.present? }
  end

  def entry_points(type)
    entries_for(type).map do |entry|
      {
        id: entry.id,
        date: entry.measured_on,
        value: display(entry.value, type),
        left:  display(entry.value_left, type),
        right: display(entry.value_right, type),
        note: entry.note,
        source: entry.source
      }
    end
  end

  def display(value, type)
    return nil if value.blank?

    round_to(Units.to_display(value, measure: type.measure, unit_system: @unit_system), type.decimals)
  end

  def round_to(value, decimals) = value&.round(decimals.to_i)&.to_f

  # Two-sided metrics have no single number, so the tile compares each side.
  def change_between(prev, last)
    return nil if prev.nil? || last.nil?

    {
      value: delta(prev[:value], last[:value]),
      left:  delta(prev[:left],  last[:left]),
      right: delta(prev[:right], last[:right])
    }.compact.presence
  end

  def delta(before, after)
    return nil if before.nil? || after.nil?

    (after - before).round(2)
  end
end
