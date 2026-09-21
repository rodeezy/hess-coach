require "rails_helper"

RSpec.describe Client do
  include_context "seeded trainer"

  describe "weeks in phase (CL-6, spec 6.4)" do
    it "counts whole weeks since the phase started, plus 1" do
      client.update!(phase_started_on: Date.current - 60)
      expect(client.weeks_in_phase).to eq(9)
    end

    it "is week 1 on the day a phase starts" do
      client.update!(phase_started_on: Date.current)
      expect(client.weeks_in_phase).to eq(1)
    end

    it "is nil when no phase has been started" do
      expect(client.weeks_in_phase).to be_nil
    end
  end

  describe "archiving (CL-1)" do
    it "hides the client but keeps their data" do
      record("body_weight", value: 80)
      client.archive!

      expect(client).to be_archived
      expect(trainer.clients.active).not_to include(client)
      expect(client.metric_entries.count).to eq(1)
    end
  end

  describe "assessment cadence (MT-6)" do
    it "is overdue when never assessed" do
      expect(client.assessment_overdue?).to be(true)
    end

    it "is not overdue inside the trainer's cadence" do
      record("body_weight", value: 80, on: Date.current - 10)
      expect(client.reload.assessment_overdue?).to be(false)
    end

    it "is overdue past the cadence, default 30 days" do
      record("body_weight", value: 80, on: Date.current - 31)
      expect(client.reload.assessment_overdue?).to be(true)
    end
  end

  it "converts height to metres for FFMI" do
    expect(client.height_m).to eq(BigDecimal("1.75"))
  end
end
RSpec.describe "Blank form values" do
  include_context "seeded trainer"

  # A form posts "" for every untouched optional field, which used to trip the
  # NULL-or-enum check constraints (UX-10: no required-field errors anywhere).
  it "stores an untouched optional select as NULL, not an empty string" do
    c = trainer.clients.create!(first_name: "Dana", disc_type: "", sex: "", email: "", phone: "")

    expect(c.reload.disc_type).to be_nil
    expect(c.sex).to be_nil
    expect(c.email).to be_nil
  end

  it "still accepts a real DiSC type" do
    c = trainer.clients.create!(first_name: "Dana", disc_type: "S")
    expect(c.reload.disc_type).to eq("S")
  end

  it "stores an untagged note as NULL" do
    c = trainer.clients.create!(first_name: "Dana")
    note = c.notes.create!(body: "Sore left knee", tag: "")
    expect(note.reload.tag).to be_nil
  end

  it "stores a sourceless metric entry as NULL" do
    c = trainer.clients.create!(first_name: "Dana")
    entry = c.metric_entries.create!(metric_type: metric("body_weight"),
                                     measured_on: Date.current, value: 80, source: "")
    expect(entry.reload.source).to be_nil
  end
end
