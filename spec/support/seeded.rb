RSpec.shared_context "seeded trainer" do
  let(:trainer) { Trainer.create!(email_address: "j@hess.test", password: "secret123") }
  let(:client) do
    trainer.clients.create!(first_name: "Dana", last_name: "Lee",
                            height_cm: 175, start_date: Date.new(2026, 1, 1))
  end

  before do
    Seeds::Lookups.call(trainer)
    Seeds::MetricTypes.call
  end

  def metric(key) = MetricType.find_by!(key: key)

  def record(key, value: nil, left: nil, right: nil, on: Date.current)
    client.metric_entries.create!(
      metric_type: metric(key), measured_on: on,
      value: value, value_left: left, value_right: right
    )
  end
end
